##################################################
# File: instance.tf                              #
# Created Date: 20190326                         #
# Author: Fred Stuck                             #
# Version: 0.1                                   #
# Description: Creates RackTables Instance       #
#                                                #
# Change History:                                #
# 20190326: Initial File                         #
#                                                #
##################################################

resource "aws_instance" "instance" {
  instance_type = "${var.instance_type}"
  associate_public_ip_address = "${var.associate_public_ip_address}"
  vpc_security_group_ids = ["${compact(concat(split(",", aws_security_group.sec-instance.id), var.sec_group_ids))}"]
  ami = "${var.ami}"
  subnet_id = "${var.subnet[count.index]}"
  key_name = "${var.key_name}" 
  iam_instance_profile = "${coalesce(var.aws_iam_instance_profile_name , aws_iam_instance_profile.profile.name)}"

  user_data = "${data.template_file.racktables_shell_script.rendered}"

  provisioner "file" {
    source      = "${path.module}/files/plugins.tar.gz"
    destination = "/tmp/plugins.tar.gz"
    
    connection {
      user = "centos"
      type = "ssh"
      private_key="${file("${var.private_key_file}")}"
      agent = true
      timeout = "3m"
    }
  }

  provisioner "file" {
    source      = "${path.module}/files/secret.php"
    destination = "/tmp/secret.php"

    connection {
      user = "centos"
      type = "ssh"
      private_key="${file("${var.private_key_file}")}"
      agent = true
      timeout = "3m"
    }
  }
  
  provisioner "file" {
    source      = "${path.module}/files/rtbackup.sh"
    destination = "/tmp/rtbackup.sh"
    
    connection {
      user = "centos"
      type = "ssh"
      private_key="${file("${var.private_key_file}")}"
      agent = true
      timeout = "3m"
    }
  }

  provisioner "file" {
    source      = "${path.module}/files/racktables-blankdb.sql"
    destination = "/tmp/racktables-blankdb.sql"
    connection {
      user = "centos"
      type = "ssh"
      private_key="${file("${var.private_key_file}")}"
      agent = true
      timeout = "3m"
    }
  }

  tags = "${merge(var.tags,map("Name",format("%s", var.instance_prefix)))}"
}

resource "aws_s3_bucket" "backup_bucket" {
  bucket = "${var.instance_prefix}-${var.app}-${var.env}-bucket"
  acl = "private"

  lifecycle_rule {
    id = "${var.instance_prefix}-${var.app}-${var.env}-rule"
    prefix = "/"
    enabled = true

    transition {
      days = "${var.s3_transition_days}"
      storage_class = "GLACIER"
    }
    expiration {
      days = "${var.s3_expiration_days}"
    }
  }

  tags = "${merge(var.tags,map("Name",format("%s", "${var.instance_prefix}-${var.app}-${var.env}-bucket")))}"
}

resource "aws_iam_instance_profile" "profile" {
  count = "${var.aws_iam_instance_profile_name == "" ? 1 : 0}"
  name = "${var.instance_prefix}-${var.app}-app-${var.env}-profile"
  role = "${join(",",aws_iam_role.role.*.id)}"
}


resource "aws_iam_role" "role" {
  count = "${var.aws_iam_instance_profile_name == "" ? 1 : 0}"
  name = "${var.instance_prefix}-${var.app}-app-${var.env}-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "policy" {
  count = "${var.aws_iam_instance_profile_name == "" ? 1 : 0}"
  name = "${var.instance_prefix}-${var.app}-app-${var.env}-policy"
  role = "${join(",",aws_iam_role.role.*.id)}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": ["arn:aws:s3:::${var.instance_prefix}-${var.app}-${var.env}-bucket/*"]
    },
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": ["arn:aws:s3:::${var.instance_prefix}-${var.app}-${var.env}-bucket/*"]
    },
    {
      "Effect": "Allow",
      "Action": "ec2:DescribeTags",
      "Resource": ["*"]
    }
  ]
}
EOF
}

data "template_file" "racktables_shell_script" {
  template = <<-EOF
#!/bin/bash -x
SCRIPT_LOG='/var/log/build.log';
RACKUSER_PW='${var.rackdb_password}'; 

touch $SCRIPT_LOG; 
date >> $SCRIPT_LOG
echo "Starting Build Process" >> $SCRIPT_LOG; 
CENTOS_VER=`cat /etc/redhat-release | awk '{ print $4 }' | cut -f1 -d.`
echo "Identified Centos '$CENTOS_VER'" >> $SCRIPT_LOG; 

rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm &>> $SCRIPT_LOG; 
rpm -Uvh https://rpms.remirepo.net/enterprise/remi-release-7.rpm &>> $SCRIPT_LOG; 
cp /etc/yum.repos.d/remi.repo /etc/yum.repos.d/remi.repo.bak &>> $SCRIPT_LOG; 
sed -i '/\[remi\]/,/^ *\[/ s/enabled=0/enabled=1/' /etc/yum.repos.d/remi.repo; &>> $SCRIPT_LOG; 
sed -i '/\[remi-php56\]/,/^ *\[/ s/enabled=0/enabled=1/' /etc/yum.repos.d/remi.repo; &>> $SCRIPT_LOG; 

yum install -y awscli.noarch cloud-utils.x86_64 python-boto.noarch s3cmd &>> $SCRIPT_LOG; 
yum -y install httpd.x86_64 mod_nss.x86_64 mariadb-server.x86_64 php.x86_64 php-gd.x86_64 php-snmp.x86_64 php-mbstring.x86_64 php-bcmath.x86_64 php-ldap.x86_64 php-mysql.x86_64 openldap-clients.x86_64 
yum -y install wget.x86_64 nano.x86_64 traceroute.x86_64 bind-utils.x86_64 mlocate.x86_64 &>> $SCRIPT_LOG; 
 
REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | awk -F\" '{print $4}')
HOSTNAME=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$(ec2metadata --instance-id)" "Name=key,Values="Name"" --region $REGION --output=text | cut -f5)
if [[ $CENTOS_VER = "7" ]];
then
  sed -i "s/- set_hostname/#-set_hostname/g" /etc/cloud/cloud.cfg
  sed -i "s/- update_hostname/#-update_hostname/g" /etc/cloud/cloud.cfg
  hostnamectl set-hostname $HOSTNAME
elif [[ $RH_VER = "6" || $CENTOS_VER = "6" ]];
then
  sed -i "s/HOSTNAME*/HOSTNAME=$HOSTNAME/g" /etc/sysconfig/network
  hostname $HOSTNAME
fi

sed -i 's/8443/443/' /etc/httpd/conf.d/nss.conf &>> $SCRIPT_LOG; 
sed -i 's/Options Indexes FollowSymLinks/Options FollowSymLinks/' /etc/httpd/conf/httpd.conf &>> $SCRIPT_LOG; 
mv /etc/httpd/conf.d/welcome.conf /etc/httpd/conf.d/welcome.conf.old; 
echo "<meta http-equiv=\"refresh\" content=\"0; url=/racktables\" />"  > /var/www/html/index.html; 

systemctl enable mariadb.service &>> $SCRIPT_LOG; 
systemctl enable httpd.service &>> $SCRIPT_LOG; 
systemctl stop httpd >> $SCRIPT_LOG;
systemctl start httpd &>> $SCRIPT_LOG; 
systemctl start mariadb &>> $SCRIPT_LOG; 

cd /tmp/; 
wget --no-check-certificate https://downloads.sourceforge.net/project/racktables/${var.rtfilename} &>> $SCRIPT_LOG; 
mkdir RackTables &>> $SCRIPT_LOG; 
tar -xvzf ${var.rtfilename} -C RackTables --strip 1 &>> $SCRIPT_LOG; 
cp -r RackTables/wwwroot /var/www/html/racktables &>> $SCRIPT_LOG; 
mkdir /var/www/html/racktables/plugins >> $SCRIPT_LOG; 
sed -i.bak 's#/\.\./plugins#/plugins#' /var/www/html/racktables/inc/pre-init.php; &>> $SCRIPT_LOG; 
tar -xvzf plugins.tar.gz &>> $SCRIPT_LOG; 
cp -r ./plugins/. /var/www/html/racktables/plugins &>> $SCRIPT_LOG; 
cp secret.php /var/www/html/racktables/inc/secret.php &>> $SCRIPT_LOG; 
sed -i "s/<RACKPASSWORD>/$RACKUSER_PW/" /var/www/html/racktables/inc/secret.php &>> $SCRIPT_LOG; 
cp rtbackup.sh /opt/rtbackup.sh &>> $SCRIPT_LOG; 
sed -i "s/<RACKPASSWORD>/$RACKUSER_PW/" /opt/rtbackup.sh &>> $SCRIPT_LOG; 
sed -i "s/<RACKBUCKET>/${aws_s3_bucket.backup_bucket.id}/" /opt/rtbackup.sh &>> $SCRIPT_LOG;
sed -i -e 's/\r$//' /opt/rtbackup.sh &>> $SCRIPT_LOG;
chmod 777 /opt/rtbackup.sh &>> $SCRIPT_LOG; 
mkdir /racktables_backups &>> $SCRIPT_LOG; 

echo "Create racktables db" >> $SCRIPT_LOG; 
mysql -uroot -Bse "create database racktables; grant all on racktables.* to root; grant all on racktables.* to root@localhost; grant all on racktables.* to rackuser; grant all on racktables.* to rackuser@localhost; set password for rackuser@localhost=password('$RACKUSER_PW');" &>> $SCRIPT_LOG; 
mysql -uroot racktables < racktables-blankdb.sql &>> $SCRIPT_LOG; 
mysql -uroot racktables -Bse "UPDATE UserAccount SET user_name = 'admin', user_password_hash = SHA1('${var.rackadmin_password}') where user_id = 1;"

touch /root/.s3cfg
echo "[default]" >> /root/.s3cfg
echo "access_key =" >> /root/.s3cfg
echo "secret_key = " >> /root/.s3cfg
echo "security_token =" >> /root/.s3cfg

yum update -y &>> $SCRIPT_LOG; 
updatedb &>> $SCRIPT_LOG; 

date >> $SCRIPT_LOG
echo "Finished Build Process" >> $SCRIPT_LOG; 
  EOF
}

resource "aws_security_group" "sec-instance" {
  name = "${var.instance_prefix}-${var.app}-${var.env}-001"
  vpc_id = "${var.vpc_id}"

  tags = "${merge(var.tags,map("Name",format("%s", "${var.instance_prefix}-${var.app}-${var.env}-001")))}"

 ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["${var.sec_group_source}"]
      
  }

  ingress {
      from_port = 443
      to_port = 443
      protocol = "tcp"
      cidr_blocks = ["${var.sec_group_source}"]
  }

  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["${var.sec_group_source}"]
  }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}
