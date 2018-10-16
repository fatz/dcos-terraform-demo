# Mesospher DEMO Day
This demo will show DC/OS Terraform

So we will perform following tasks

<!-- TOC START min:1 max:3 link:true update:true -->
- [Mesospher DEMO Day](#mesospher-demo-day)
  - [Start a cluster on AWS ( 1.11.5 )](#start-a-cluster-on-aws--1115-)
  - [Teardown the AWS Cluster and Start a new one with same settings on GCP](#teardown-the-aws-cluster-and-start-a-new-one-with-same-settings-on-gcp)
  - [Update 1.11.5 => 1.11.6](#update-1115--1116)
  - [Go from Open Source to Enterprise](#go-from-open-source-to-enterprise)
- [Cleanup the demo](#cleanup-the-demo)

<!-- TOC END -->



## Start a cluster on AWS ( 1.11.5 )
We start with this [main.tf](./main.tf)

Prerequisites are a properly setup cloud tooling e.g. credentials, default region or default profile

First we need to initialize our modules. Terraform now receives all modules from the registry and installs all necessary provider binaries.

```
$ terraform init
```

```hcl
variable "dcos_install_mode" {
  description = "specifies which type of command to execute. Options: install or upgrade"
  default     = "install"
}

data "http" "whatismyip" {
  url = "http://whatismyip.akamai.com/"
}

provider "aws" {}
provider "google" {}

module "dcos" {
  source = "dcos-terraform/dcos/aws"

  cluster_name        = "mesosphere-demo-day"
  ssh_public_key_file = "~/.ssh/id_rsa.pub"
  admin_ips           = ["${data.http.whatismyip.body}/32"]

  num_masters        = "1"
  num_private_agents = "2"
  num_public_agents  = "1"

  dcos_version = "1.11.5"
  dcos_variant = "open"

  # dcos_variant              = "ee"
  # dcos_license_key_contents = "${file("./license.txt")}"

  dcos_install_mode = "${var.dcos_install_mode}"
  dcos_instance_os  = "centos_7.3"
  providers {
    "aws"    = "aws"
    "google" = "google"
  }
}

output "masters-ips" {
  value = "${module.dcos.masters-ips}"
}

output "cluster-address" {
  value = "${module.dcos.masters-loadbalancer}"
}

output "public-agents-loadbalancer" {
  value = "${module.dcos.public-agents-loadbalancer}"
}

```

now apply this and boot the cluster

```
$ terraform apply
```

## Teardown the AWS Cluster and Start a new one with same settings on GCP
The next step is to see how easy it is to adopt a different cloud provider.

We simply change the source from `aws` to `gcp`

```hcl
# ...
module "dcos" {
  source = "dcos-terraform/dcos/gcp"
  # ...
}
# ...
```

another apply will destroy the AWS cluster and create a new GCP one.

```
$ terraform apply
```

## Update 1.11.5 => 1.11.6
lets change the version to `1.11.6`

```hcl
# ...
module "dcos" {
  # ...
  dcos_version = "1.11.6"
  # ...
}
# ...
```

Due to some limitation in this method we have to explicitly state an upgrade operation.
__NOTE: It is not possible to upgrade and scale at the same time__

```
$ terraform apply -var dcos_install_mode=upgrade
```

## Go from Open Source to Enterprise
to change from open source to enterprise edition we have to change the `dcos_variant` and state a `dcos_license_key_contents` string.

```hcl
# ...
module "dcos" {
  # ...
  dcos_variant              = "ee"
  dcos_license_key_contents = "${file("./license.txt")}"
  # ...
}
# ...
```

this is also an upgrade ( same version upgrade )

```
$ terraform apply -var dcos_install_mode=upgrade
```


# Cleanup the demo
```
$ terraform destroy
$ git checkout -- main.tf
$ rm -R .terraform
```
