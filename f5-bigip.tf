resource "random_id" "id" {
  byte_length = 2
}

resource "random_string" "password" {
  length      = 16
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
  special     = false
}



resource "aws_iam_role" "main" {
  name               = format("%s-iam-role-%s", var.prefix, random_id.id.hex)
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


resource "aws_iam_role_policy" "BigIpPolicy" {
  //name = "aws-iam-role-policy-${module.utils.env_prefix}"
  role   = aws_iam_role.main.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Action": [
            "ec2:DescribeInstances",
            "ec2:DescribeInstanceStatus",
            "ec2:DescribeAddresses",
            "ec2:AssociateAddress",
            "ec2:DisassociateAddress",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DescribeNetworkInterfaceAttribute",
            "ec2:DescribeRouteTables",
            "ec2:ReplaceRoute",
            "ec2:CreateRoute",
            "ec2:assignprivateipaddresses",
            "sts:AssumeRole",
            "s3:ListAllMyBuckets"
        ],
        "Resource": [
            "*"
        ],
        "Effect": "Allow"
    },
    {
        "Effect": "Allow",
        "Action": [
            "secretsmanager:GetResourcePolicy",
            "secretsmanager:GetSecretValue",
            "secretsmanager:DescribeSecret",
            "secretsmanager:ListSecretVersionIds",
            "secretsmanager:UpdateSecretVersionStage"
        ],
        "Resource": [
            "arn:aws:secretsmanager:${var.region}:${module.vpc.vpc_owner_id}:secret:*"
        ]
    }
  ]
}
EOF
}


resource "aws_iam_instance_profile" "instance_profile" {
  name = format("%s-iam-profile-%s", var.prefix, random_id.id.hex)
  role = aws_iam_role.main.id
}

#
# Create Secret Store and Store BIG-IP Password
#
resource "aws_secretsmanager_secret" "bigip" {
  name = format("%s-bigip-secret-%s", var.prefix, random_id.id.hex)
}

resource "aws_secretsmanager_secret_version" "bigip-pwd" {
  secret_id     = aws_secretsmanager_secret.bigip.id
  secret_string = random_string.password.result
}



data "template_file" "user_data_vm0" {
  template = file("./scripts/custom_onboard_big.tmpl")
  vars = {
    bigip_username = var.f5_username
    aws_secretmanager_auth = false
    INIT_URL       = "https://cdn.f5.com/product/cloudsolutions/f5-bigip-runtime-init/v1.4.1/dist/f5-bigip-runtime-init-1.4.1-1.gz.run",
    DO_URL         = "https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.21.0/f5-declarative-onboarding-1.21.0-3.noarch.rpm",
    DO_VER         = "v1.29.0"
    AS3_URL        = "https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.36.0/f5-appsvcs-3.36.0-6.noarch.rpm",
    AS3_VER        = "v3.36.0"
    FAST_URL       = "https://github.com/F5Networks/f5-appsvcs-templates/releases/download/v1.8.1/f5-appsvcs-templates-1.8.1-1.noarch.rpm"
    FAST_VER       = "v1.8.1"
    bigip_password = random_string.password.result
  }
}


module "bigip" {
  count                       = 1
  source                      = "F5Networks/bigip-module/aws"
  prefix                      = "${var.prefix}-bigip"
  ec2_instance_type           = "m5.large"
  ec2_key_name                = aws_key_pair.demo.key_name
  f5_ami_search_name          = var.f5_ami_search_name
  f5_password                 = random_string.password.result
  mgmt_subnet_ids             = [{ "subnet_id" = module.vpc.public_subnets[0], "public_ip" = true, "private_ip_primary" = "${var.f5mgmtip}" }]
  mgmt_securitygroup_ids      = [aws_security_group.f5.id]
  custom_user_data            = data.template_file.user_data_vm0.rendered
}
