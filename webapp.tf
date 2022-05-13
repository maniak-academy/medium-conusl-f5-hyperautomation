resource "aws_autoscaling_group" "webapp" {
  name                 = "${var.prefix}-webapp-asg"
  launch_configuration = aws_launch_configuration.webapp.name
  desired_capacity     = 2
  min_size             = 1
  max_size             = 4
  vpc_zone_identifier  = [module.vpc.public_subnets[0]]

  lifecycle {
    create_before_destroy = true
  }



  tags = [
    {
      key                 = "Name"
      value               = "${var.prefix}-webapp"
      propagate_at_launch = true
    },
    {
      key                 = "Env"
      value               = "consul"
      propagate_at_launch = true
    },
  ]

}

resource "aws_launch_configuration" "webapp" {
  name_prefix                 = "${var.prefix}-webapp-"
  image_id                    = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  associate_public_ip_address = true

  security_groups = [aws_security_group.webapp.id]
  key_name        = aws_key_pair.demo.key_name
  user_data       = file("./scripts/webapp.sh")

  iam_instance_profile = aws_iam_instance_profile.consul.name

  lifecycle {
    create_before_destroy = true
  }
}
