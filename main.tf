variable "dcos_install_mode" {
  description = "specifies which type of command to execute. Options: install or upgrade"
  default     = "install"
}

data "http" "whatismyip" {
  url = "http://whatismyip.akamai.com/"
}

provider "aws" {}
provider "google" {}

##########################
##
## DC/OS Terraform Module
##
##########################

module "dcos" {
  source = "dcos-terraform/dcos/aws"

  cluster_name        = "mesosphere-demo-day-julferts"
  ssh_public_key_file = "~/.ssh/id_rsa.pub"
  admin_ips           = ["${data.http.whatismyip.body}/32"]

  num_masters        = "1"
  num_private_agents = "1"
  num_public_agents  = "1"

  dcos_version = "1.11.5"
  dcos_variant = "open"

  # dcos_variant              = "ee"
  # dcos_license_key_contents = "${file("./license.txt")}"

  dcos_install_mode = "${var.dcos_install_mode}"
  providers {
    "aws"    = "aws"    #this is only for demo cases
    "google" = "google"
  }
}

##########################
##########################
##########################
##########################

output "masters-ips" {
  value = "${module.dcos.masters-ips}"
}

output "cluster-address" {
  value = "${module.dcos.masters-loadbalancer}"
}

output "public-agents-loadbalancer" {
  value = "${module.dcos.public-agents-loadbalancer}"
}
