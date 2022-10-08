variable "instancetype" {
  default = "t2.micro"
}

# if no explicit value is provided then the default value configured here is used
# variable value can be passed from command line -
#   terrafrom plan -var="instancetype=t2.small"
# if environment vairable exists then that variable will be used
#   export TF_VAR_instancetype="m5.large"
# if terraform.tfvars file exists the vaue defined in that file is used 
