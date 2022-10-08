# Terraform and Git

We can store our terraform configuration in a git repository.

Its important to not commit `terraform.tfstate` file or any file which can have or contains sensisitive information.

> Important Note:
While committing data to the Git repository,  please avoid pushing your access/secret keys with the code. This is very important.

---
# Module Sources in Terraform 

- The `source` argument in a `module` block tells terraform where to find the source code for the desired child module
- Supported Module Sources 
  - Local Paths
  - Terraform Registry
  - GitHub
  - BitBucket
  - Generic Git, Mercurial repositories
  - HTTP URLs
  - S3 buckets
  - GCS buckets

## Local Path Module Source

A local path must begin with either ./ or ../ to indicate that a local path is intended
```
module "consul" {
  source = "../consul"
}
```

## Git Module Source 

Arbitary Git repositories can be used as module source by prefixing the address with the special `git::` prefix, After this prefix any valid Git URL can be specified to select one of the protocols supported by Git.

```
module "vpc" {
    source = "git::https://example.com/vpc.git"
}

module "storage" {
    source = "git::ssh://username@example.com/storage.git"
}
```

### Referencing to a Branch

By default, Terraform will clone and use the default branch (refernced by HEAD) in the selected repository.

You can override this using the ref query string in source git url `git::https://example.com/vpc.git?ref=v1.2.0`, value of ref can be any refernce that would be accepted by the git checkout command, including branch and tag names.

```
module "vpc" {
    source = "git::https://example.com/vpc.git?ref=v1.2.0"
}
```
---

# Terraform and `.gitignore`

- The `.gitignore` file is a text file that tells git which files and folders to ignore in a project.
- Depending on environment, it is recommended to avoid commiting certain files to git.

| Files to Ignore | Description |
|--|--|
| `.terraform`, `**/.terraform/*`  | This is local terraform directory which gets recreated when we run terraform init and is not required to be checked in |
| `*.tfvars` | Likely to contain some sensitive data |
| `*.tfstate`, `*.tfstate.*` | Contains sensitive data and should be stored in remote |
| `crash.log`, `crash.*.log`  | If terraform crashes logs are stored in `crash.log`, `crash.*.log` files |

- `.gitignore` file example for terraform repositories <https://github.com/github/gitignore/blob/main/Terraform.gitignore>

---

# Terraform Backends

- Backends define where Terraform's state snapshots are stored.
- A given Terraform configuration can either specify a backend, integrate with Terraform Cloud, or do neither and default to storing state locally.
- Backends primarily determine where Terraform stores its state. 
- By default, Terraform implicitly uses a backend called `local` to store state as a local file on disk. 

## Ideal Architecture
- The Terraform code is stored in Git repository
- The State file is stored in a Central backend

## Backends supported in Terraform

- Terraform supports multiple backends that allows remote service related operations 
- Some of the popular backends include :
  - S3
  - consul
  - Azurerm 
  - Kubernetes
  - HTTP
  - ETCD
- Important Note 
  - Accessing state in a remote service generally requires some kind of access credentials
  - Some backends act like plain "remote disks" for state files; others support locking the state while operations are being performed, which helps prevent conflicts and inconsistencies.

---
# Implementing `S3` backend

- Create an AWS S3 bucket with default options
- Add below backend configuration for terraform
- Authenticate using AWS CLI `aws configure`

```
terraform {
  backend "s3" {
    bucket = "ablabs-terraform-backend"
    key    = "terraform.tfstate"
    region = "us-west-2"
  }
}
```
---

# State File Locking

- Whenever we are performing write operations, terraform would lock the state file. 
- This is very important as otherwise during our ongoing terraform apply operations, if others also try for the same, it can corrupt our state file.
- By default S3 backend doesnot supports terraform state file lock.

Important Note
- State locking happens automatically on all operations that could write the state. You won't see any message that it is happening 
- If state locking fails, terraform will not continue
- Not all backends support locking. The documentation for each backend includes details on weather it supports locking or not.

Force Unlocking State
- Terraform has `force-unlock` command to manually unlock the state if unlocking failed
- If you unlock the state when someone else is holding the lock it could cause multiple writers
- Force unlock should only be used to unlock your own lock in the situation where automatic unlocking failed

---
# Integrating Dynamo DB with S3 backend for state locking

- By default, S3 does not support State Locking functionality
- we can use DynamoDB table to achieve state locking functionality

__DynamoDB State Locking__

`dynamodb_table` - (Optional) Name of DynamoDB Table to use for state locking and consistency. The table must have a partition key named `LockID` with type of `String`. If not configured, state locking will be disabled.

```
terraform {
  backend "s3" {
    bucket = "ablabs-terraform-backend"
    key    = "terraform.tfstate"
    region = "us-west-2"
    dynamodb_table = "terraform-s3-state-lock"
  }
}
```

When we run terraform plan, terraform acquires state lock.

---

# Terraform State Management

- As our terraform usage becomes more advanced, there are some cases where we may need to modify the Terraform state. It is important to never modify terraform state file direclty. Instead, make use of `terraform state` command.

## State Modification
The `terraform state` command is used for advanced state management. As your Terraform usage becomes more advanced, there are some cases where you may need to modify the Terraform state. Rather than modify the state directly, the `terraform state` commands can be used in many cases instead.

| `terraform state` subcommand | Description |
|--|--|
| `list` | List resources within terraform state file |
| `mv` | move items in a terraform state |
| `pull` | manually download and output the state from remote state |
| `push` | manually upload local state file to remote state |
| `rm` | removes item from terraform state |
| `show` | show the attributes of a single resource in the state |

__List__

- `terraform state list` command is used to list resources within a terraform state 
  ```
  terraform state list
  aws_iam_user.lb
  aws_instance.webapp
  ```

__Move__

- The `terraform state mv` command is used to move items in a Terraform state.
- This command is used in many cases in which you want to __rename__ an existing resource without destroying and recreating it.
- Due to the destructive nature of this command, this command will output a backup copy of the state prior to saving any changes

synatx

```
terraform state mv [options] SOURCE DESTINATION
```

Example case

You have following EC2 resource 

```
resource "aws_instance" "myec2" {
    ami = "ami-00f7e5c52c0f43726"
    instance_type = "t2.micro"
}
```

We want to change the name from `myec2` to `webapp`

```
resource "aws_instance" "webapp" {
    ami = "ami-00f7e5c52c0f43726"
    instance_type = "t2.micro"
}
```

Terraform will now try to destroy the resource and recreate it. This is something which would not want always.

We can use `terraform state move` command here

```
terraform state mv aws_instance.myec2 aws_instance.webapp
```

Terraform will now not show to destroy the resource and recreate it.


__Pull__

- The `terraform state pull` command is used to manually download and output the state from remote state. This command also works with local state.

- This is useful for reading values out of state (potentially pairing this command with something like `jq` ). 

```
terraform state pull
```

__Push__

The `terraform state push` command is used to manually upload a local state file to remote state.

This command should rarely be used.

__Remove__

- `terraform state rm` command is used to remove items from the terraform state
- items removed from the terraform state are not physically destroyed
- items removed from the terraform state are no longer managed by terraform
- for example, if we remove an AWS instance from the state, the AWS instance will continue running, but terraform plan will no longer see the instance

```
terraform state rm aws_instance.myec2
```

__Show__

The `terraform state show` command is used to show the attributes of a single resource in the Terraform state.

```
terraform state show aws_instance.myec2
```

---
# Connecting Remote States

- The `terraform-remote-state` data source retrieves the root module output values from some other Terraform configuration, using the latest snapshot from the remote backend 

Example

Project1 > Public Ips > Remote State > S3 Bucket > Output Values

Project2 > Security Group > Fetcch Output values from Public IPs Remote State > Whitelist

## Implementing Remote States Connections


`network-project/backend.tf`
```
terraform {
  backend "s3" {
    bucket = "ablearn-terraform-backens"
    key = "network/eip.tfstate"
    region = "use-east-1"
  }
}
```

`network-project/eip.tf`
```
resource "aws_eip" "lb" {
  vpc = true
}

output "eip_addr" {
  value = "aws_eip.lb.public_ip"
}

```


`security-project/remote-state.tf`
```
data "tearraform_remote_state" "eip" {
  backend = "s3"

  config = {
    bucket = "ablearn-terraform-backens"
    key = "network/eip.tfstate"
    region = "use-east-1"
  }

}
```

`security-project/sg.tf`
```
resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["${data.terraform_remote_state.eip.outputs.eip_addr}/32"] # remote state
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
```


---


# Import existing resource using Terraform Import 

- Terraform is able to import existing infrastructure. 
- This allows you take resources you've created by some other means and bring it under Terraform management.

- The current implementation of Terraform import can only import resources into the state. It does not generate configuration. 

- Because of this, prior to running `terraform import`, it is necessary to write manually a `resource` configuration block for the resource, to which the imported object will be mapped.


Manually write the resource configuration block for the resouce you wish to import

create `ec2.tf`
```
resource "aws_instance" "myec2" {
    ami = "ami-00f7e5c52c0f43726"
    instance_type = "t2.micro"
    vpc_security_group_ids = ["sg-0b784705b047aaf23"]
    key_name = "terraform-key"
    tags {
        Name = "manual-ec2"
    }
}
```

```
terraform init
```

Run terraform import command 
```
terraform import aws_instance.myec2 <instanceid-of-actual-instance>
```

```
terraform plan
```
---
