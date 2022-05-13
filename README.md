# Network Infrastructure Automation Demo with Consul and F5 BIG-IP

The following code builds an Consul Service Networking - Network Automation Infrastruction environmnet that automatically builds F5 configurations based on what the app team has registered with the service mesh. 


## Prerequisites
You will require the following access to make this lab work
* AWS access 
* Terraform Installed

## Deploy the demo environment using Terraform 

The tutorial provides an example scenario that can be deployed on AWS using Terraform.

```
git clone https://github.com/maniak-academy/medium-conusl-f5-hyperautomation.git
```

For this demo we need to configure AWS credentials for your environment so that Terraform can authenticate with AWS and create resources.
To do this with IAM user authentication, set your AWS access key ID as an environment variable.

```
export AWS_ACCESS_KEY_ID="<YOUR_AWS_ACCESS_KEY_ID>"
```

Now set your secret key.

```
export AWS_SECRET_ACCESS_KEY="<YOUR_AWS_SECRET_ACCESS_KEY>"
```

## Deploy Consul datacenter and F5 BIG-IP
The Terraform code for deploying the Consul datacenter and the BIG-IP instance is under the root folder.


Use the terraform.tfvars.example template file to create a terraform.tfvars file. The example file is in the terraform folder.

Edit the file to specify a prefix for the resources being created and an IP address to access the environment once deployed.

```
#prefix 

prefix = "your-prefix"

# IP address to allow traffic from
# recommended to use a /32 (single IP address)

allow_from = "192.0.2.0/32"

# environment options

# region = "us-east-1"
# f5_ami_search_name = "F5 BIGIP-16.1.2* PAYG-Good 25Mbps*"
# f5_username = "bigipuser"
```

Once the configuration is complete, you can deploy the infrastructure with Terraform.

First, initialize Terraform.

```
terraform init
```

Then, use terraform plan to check the resources that are going to be created.

```
terraform init
```

Finally, apply the changes.

```
terraform apply -auto-approve
```

Here are the outputs 

```
Apply complete! Resources: 27 added, 0 changed, 0 destroyed.

Outputs:

Consul_SSH = "ssh -i terraform-20220513161032519200000001.pem ubuntu@54.197.55.193"
Consul_UI = "http://54.197.55.193:8500"
Copy-CTS-Config = "scp -i terraform-20220513161032519200000001.pem cts-config/cts-config.hcl ubuntu@54.197.55.193:/home/ubuntu/"
F5_Password = "76JfmNGKSXDBW9Bh"
F5_UI = "https://44.205.27.212:8443"
F5_Username = "admin"
F5_ssh = "ssh -i terraform-20220513161032519200000001.pem admin@44.205.27.212"
```

The final part of the Terraform output provides you with the information to access your infrastructure.

From the Consul UI you can verify the datacenter contains two instances of NGINX running on two different nodes.

By opening your browser at the URL specified by the F5_UI variable, you can access your F5 BIG-IP instance GUI.

After the device finishes booting, use the F5_Username and F5_Password values to login.

## Network Infrastructure Automation
With all the components installed you can now start Consul-Terraform-Sync to automatically provision the F5 BIG-IP configuration to load balance the webapps based on the metadata in Consul.

First, lets SCP the cts-config.hcl file that was generated to our consul server.


```
scp -i terraform-20220513161032519200000001.pem cts-config/cts-config.hcl ubuntu@54.197.55.193:/home/ubuntu/
```

Now let's log into our consul server to start consul-terraform-sync. The outcome will be the full deploymented of an F5 Application. 

```
sudo consul-terraform-sync start -config-file cts-config.hcl
```


## Test our Automation
To verify the integration is working, add more webapp instances by editing the AWS Auto Scaling group configuration.

Edit the webapp.tf file inside the terraform folder to change the desired capacity from 2 to 4.

```
resource "aws_autoscaling_group" "nginx" {
  name                 = "${var.prefix}-nginx-asg"
  launch_configuration = aws_launch_configuration.nginx.name
  desired_capacity     = 4
  min_size             = 1
  max_size             = 4
  vpc_zone_identifier  = [module.vpc.public_subnets[0]]

  lifecycle {
    create_before_destroy = true
  }

...
```

Then, use terraform plan to check the resources that are going to be changed.

```
terraform plan
```

Finally, apply the changes.

```
terraform apply -auto-approve
```

Once the changes are applied on AWS, Consul will show the new instances on the Services tab.

Consul-Terraform-Sync will pick the change from the Consul catalog and modify the BIG-IP configuration to reflect the new webapp instances.

Refresh the page to verify the traffic is being balanced across the four NGINX instances.


## Clean your environment
When you are done, you can stop Consul-Terraform-Sync by either using CTRL+C in the shell running the daemon or by sending the SIGINT signal to the process.

Destroy the terraform resources

```
terraform destroy -auto-approve
```


