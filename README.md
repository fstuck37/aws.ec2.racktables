RackTables Instance
=============

This module deploys an AWS Instance with Apache, MySQL, and the RackTables application.
Once the build script is complete RackTables will be ready to use.

You can find more about RackTables on their website here: [https://www.racktables.org/](https://www.racktables.org/)

Example
------------
```
module "racktables" {
  source        = "git::https://github.com/fstuck37/aws.ec2.racktables.git"
  vpc_id        = "vpc-19c8e7ad391d45af9"
  subnet        = ["subnet-1ab174338f1224aea"]
  ami           = "ami-02eac2c0129f6376b"
  instance_prefix = "test37"
  private_key_file = "C:\\PrivKey.ppk"
  key_name    = "${aws_key_pair.racktables-key.key_name}"
  rackdb_password = "P@asword!"
  tags = {
    dept = "Development"
    Billing = "12345"
    Contact = "F. Stuck"
    Environment = "POC"
    Notes  = "This is a test environment"
  }
}

resource "aws_key_pair" "racktables-key" {
  key_name_prefix = "test37-key"
  public_key      = "C:\\PubKey.pem"
}
```

Argument Reference
------------

* **Base Settings**
   * **ami** - Required : AWS CentOS AMI to build the instance(s) with
   * **key_name** - Required : The key name of the Key Pair to use for the instance; which can be managed using the aws_key_pair resource.
   * **subnet** - Required : The Subnet ID to deploy the instance on.
   * **instance_prefix** - Required : The instance name prefix which is use for naming of instances and various other components for uniqueness.
   * **aws_iam_instance_profile_name** - Optional : Provide an IAM Instance Profile to launch instance(s) with. Specified as the name of the Instance Profile. If one is not provided one will be created
   * **instance_type** - Optional : The Instance Type, the defualt is a t2.micro.
   * **associate_public_ip_address** - Optional : create a public IP address to the instance. The default is false.
   * **sec_group_ids** - Optional : List of Security Group ID Numbers to apply to the instance. This will be added in addition to the application require ports of 80, 443, and 22.
   * **sec_group_source** - Optional : List of subnets to allow access in the default security group. The defaukt CIDR is 10.0.0.0/8.
   * **tags** - Optional : A map of tags to assign to the resource.  
   * **app** - Optional : Code used for naming componets. The default is rtb.
   * **env** - Optional : Code used for naming componets such as p for production or d for development. The default is p.
   * **s3_transition_days** - Optional : Specifies the number of days after backup object creation when it is transitioned to Glacier.  
   * **s3_expiration_days** - Optional : Specifies the number of days after object creation when the object is removed. The default is 30  
   * **vpc_id** - Required : The VPC ID to deploy the instance.
   * **rtfilename** - Optional : The RackTables file to download and install. The current default is RackTables-0.21.2.tar.gz.
   * **private_key_file** - Required : The path to the private key file. This is used for the remote provsioner to SSH into the system for post processing. Must be in OpenSSH format and on Windows pageant must be running.
   * **rackdb_password** - Required: The RackTables Database Password
   * **rackadmin_password** - Optional : The RackTables admin Password. The default is admin. It is recommended that this be changed.

Output Reference
------------
   * **id** - The instance ID
   * **private_dns** - The private DNS name assigned to the instance. Can only be used inside the Amazon EC2, and only available if you've enabled DNS hostnames for your VPC 
   * **private_ip** - The private IP address assigned to the instance
   * **public_ip** - The public IP address assigned to the instance, if applicable.
   * **public_dns** - The public DNS name assigned to the instance. For EC2-VPC, this is only available if you've enabled DNS hostnames for your VPC