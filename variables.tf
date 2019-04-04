variable "ami" {
  description = "Required : AWS CentOS AMI to build the instance(s) with"
}

variable "key_name"  {
	 description = "Required : The key name of the Key Pair to use for the instance(s); which can be crerated using the aws_key_pair resource."
}

variable "subnet" {
  description = "Required : List of subnet IDs to build the instance(s) on"
	type = "list"
}

variable "instance_prefix" {
  description = "Required : The instance name prefix which is use for naming of instances and various other components for uniqueness"
}

variable "aws_iam_instance_profile_name" {
  description = "Optional : Provide an IAM Instance Profile to launch instance(s) with. Specified as the name of the Instance Profile. If one is not provided one will be created"
  default = ""
}

variable "instance_type"  { 
  description = "Optional : The Instance Type, the defualt is a t2.micro"
	default = "t2.micro"
}

variable "associate_public_ip_address"  { 
  description = "Optional : create a public IP address to the instance"
	default = "false"
}

variable "sec_group_ids" { 
  description = "Optional : Additional Security Groups IDs to apply to the instance(s). The default is an empty list"
  type = "list"
  default = []
}

variable "sec_group_source" { 
  description = "Optional : List of subnets to allow access in the default security group."
  type = "list"
  default = ["10.0.0.0/8"]
}

variable "tags" {
	type = "map" 
  description = "Optional : A map of tags to assign to the resource."  
	default = { }
}

variable "app" {
  description = "Optional : Code used for naming componets. The default is rtb."  
	default = "rtb"
}

variable "env" {
  description = "Optional : Code used for naming componets such as p for production or d for development. The default is p."  
	default = "p"
}

variable "s3_transition_days" {
  description = "Optional : Specifies the number of days after backup object creation when it is transitioned to Glacier."  
	default = 7
}

variable "s3_expiration_days" {
  description = "Optional : Specifies the number of days after object creation when the object is removed. The default is 30"  
	default = 30
}

variable "vpc_id" {
  description = "Required : The VPC ID to deploy the instance."
}

variable "rtfilename" { 
  description = "Optional : The RackTables file to download and install. The current default is RackTables-0.21.2.tar.gz."
	default = "RackTables-0.21.2.tar.gz"
}

variable "private_key_file"  {
  description = "Required : The path to the private key file. This is used for the remote provsioner to SSH into the system for post processing. Must be in OpenSSH format and on Windows pageant must be running."
}

variable "rackdb_password" {
  description = "Required: The RackTables Database Password"
}

variable "rackadmin_password" {
  description = "Optional : The RackTables admin Password. The default is admin. It is recommended that this be changed."
  default = "admin"
}
