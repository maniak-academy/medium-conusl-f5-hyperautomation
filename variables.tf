variable "prefix" {
  description = "prefix for resources created"
  default     = "hashi-f5-demo"
}
variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}
variable "f5mgmtip" {
  description = "f5 management and vip ip address"
  default     = "10.0.0.200"
}

variable "f5_password" {
  description = "F5 username"
}

variable "f5_username" {
  description = "F5 username"
  default     = "f5admin"
}

variable "f5_ami_search_name" {
  description = "BIG-IP AMI name to search for"
  type        = string
  default     = "F5 BIGIP-16.1.2* PAYG-Good 25Mbps*"
}
variable "allow_from" {
  description = "IP Address/Network to allow traffic from (i.e. 192.0.2.11/32)"
  type        = string
}

variable "custom_user_data" {
  description = "Provide a custom bash script or cloud-init script the BIG-IP will run on creation"
  type        = string
  default     = null
}
