# Mesospher DEMO Day
This demo will show DC/OS Terraform. The purpose of the DC/OS Terraform project is to provide users with a flexible, simple and universal way to provision and manage DC/OS across multiple cloud providers. This project supports both the Open Source version and the Enterprise version. 

So we will perform the following tasks:

<!-- TOC START min:1 max:3 link:true update:true -->
- [Mesosphere DEMO Day](#mesospher-demo-day)
  - [Start a cluster on AWS ( 1.11.5 )](#start-a-cluster-on-aws--1115-)
  - [Teardown the AWS Cluster and Start a new one with same settings on GCP](#teardown-the-aws-cluster-and-start-a-new-one-with-same-settings-on-gcp)
  - [Update 1.11.5 => 1.11.6](#update-1115--1116)
  - [Go from Open Source to Enterprise](#go-from-open-source-to-enterprise)
- [Cleanup the demo](#cleanup-the-demo)

<!-- TOC END -->


## Start a cluster on AWS ( 1.11.5 )
Prerequisites are a properly setup cloud tooling e.g. credentials, default region or default profile. See the following [AWS](https://github.com/dcos-terraform/terraform-aws-dcos/tree/master/docs/quickstart#ensure-you-have-your-aws-cloud-credentials-properly-set-up) and [GCP](https://github.com/dcos-terraform/terraform-gcp-dcos/tree/master/docs/quickstart#ensure-you-have-default-application-credentials) quickstarts for more info on auth.

We start with this [main.tf](./main.tf)

```hcl
variable "dcos_install_mode" {
  description = "specifies which type of command to execute. Options: install or upgrade"
  default     = "install"
}

data "http" "whatismyip" {
  url = "http://whatismyip.akamai.com/"
}

module "dcos" {
  source = "dcos-terraform/dcos/aws"

  dcos_instance_os    = "coreos_1235.9.0"
  cluster_name        = "my-open-dcos"
  ssh_public_key_file = "~/.ssh/id_rsa.pub"
  admin_ips           = ["${data.http.whatismyip.body}/32"]

  num_masters        = "1"
  num_private_agents = "2"
  num_public_agents  = "1"

  dcos_version = "1.11.4"

  # dcos_variant              = "ee"
  # dcos_license_key_contents = "${file("./license.txt")}"
  dcos_variant = "open"

  dcos_install_mode = "${var.dcos_install_mode}"
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

First we need to initialize our modules. Terraform now receives all modules from the registry and installs all necessary provider binaries.

```
$ terraform init
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

Inialize all the modules for GCP like we did about for AWS.

``` 
$ terraform init
```

Another apply will destroy the AWS cluster and create a new GCP one.

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
