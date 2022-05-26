
output "F5_Username" {
  value = "admin"
}

output "F5_Password" {
  value = random_string.password.result
}

output "F5_ssh" {
  value = "ssh -i ${aws_key_pair.demo.key_name}.pem ${var.username}@${module.bigip.0.mgmtPublicIP}"
}

output "F5_UI" {
  value = "https://${module.bigip.0.mgmtPublicIP}:8443"
}

output "Consul_UI" {
  value = "http://${aws_instance.consul.public_ip}:8500"
}

output "Consul_SSH" {
  value = "ssh -i ${aws_key_pair.demo.key_name}.pem ubuntu@${aws_instance.consul.public_ip}"
}

output "Copy-CTS-Config" {
  value = "scp -i ${aws_key_pair.demo.key_name}.pem cts-config/cts-config.hcl ubuntu@${aws_instance.consul.public_ip}:/home/ubuntu/"
}


