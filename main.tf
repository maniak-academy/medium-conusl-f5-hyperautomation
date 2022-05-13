
terraform {
  required_providers {
    bigip = {
      source  = "F5Networks/bigip"
      version = "1.13.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.2.2"
    }
    template = {
      source  = "hashicorp/template"
      version = "2.2.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "template_file" "nia" {
  template = file("./cts-config/config.hcl.example")
  vars = {
    addr               = var.f5mgmtip
    port               = "8443"
    username           = "admin"
    pwd                = random_string.password.result
    consul             = aws_instance.consul.private_ip
  }
}
resource "local_file" "nia-config" {
  content  = data.template_file.nia.rendered
  filename = "./cts-config/cts-consul.hcl"
}


