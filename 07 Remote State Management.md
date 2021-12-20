# Terraform and Git

We can store our terraform configuration in a git repository.

Its important to not commit `terraform.tfstate` file or any file which can have or contains sensisitive information.

> Important Note:
While committing data to the Git repository,  please avoid pushing your access/secret keys with the code. This is very important.

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

## Terraform and `.gitignore`

- The `.gitignore` file is a text file that tells git which files and folders to ignore in a project.
- Depending on environment, it is recommended to avoid commiting certain files to git.

| Files to Ignore | Description |
|--|--|
| `.terraform`, `**/.terraform/*`  | This is local terraform directory which gets recreated when we run terraform init and is not required to be checked in |
| `*.tfvars` | Likely to contain some sensitive data |
| `*.tfstate`, `*.tfstate.*` | Contains sensitive data and should be stored in remote |
| `crash.log`, `crash.*.log`  | If terraform crashes logs are stored in `crash.log`, `crash.*.log` files |

- `.gitignore` file example for terraform repositories <https://github.com/github/gitignore/blob/main/Terraform.gitignore>

`.gitignore`
```
.terraform/
*.tfvars
*.tfstate
```

# Remote State Management with Terraform

## Backend

Backends define where Terraform's state snapshots are stored.

A given Terraform configuration can either specify a backend, integrate with Terraform Cloud, or do neither and default to storing state locally.

Backends primarily determine where Terraform stores its state. By default, Terraform implicitly uses a backend called `local` to store state as a local file on disk. 

### Available Backends
Terraform includes a built-in selection of backends. The built-in backends are the only backends. You cannot load additional backends as plugins. Depending on backend which is being used there can be various features. There are many built-in backends some of them are -


- `local`
  - The local backend stores state on the local filesystem, locks that state using system APIs, and performs operations locally.

- `remote`
  - The remote backend is unique among all other Terraform backends because it can both store state snapshots and execute operations for Terraform Cloud's CLI-driven run workflow. It used to be called an "enhanced" backend.

- `s3`
  - Stores the state as a given key in a given bucket on Amazon S3. This backend also supports state locking and consistency checking via Dynamo DB, which can be enabled by setting the `dynamodb_table` field to an existing DynamoDB table name. A single DynamoDB table can be used to lock multiple remote state files. Terraform generates key names that include the values of the `bucket` and `key` variables.
    
    > Warning! It is highly recommended that you enable Bucket Versioning on the S3 bucket to allow for state recovery in the case of accidental deletions and human error.

## Implementing `S3` backend

- Create an AWS S3 bucket with default options
- Add below backend configuration for terraform

```
terraform {
  backend "s3" {
    bucket = "ablabs-terraform-backend"
    key    = "terraform.tfstate"
    region = "us-west-2"
  }
}
```

## State File Locking and challenges

Whenever we are performing write operations, terraform would lock the state file. This is very important as otherwise during our ongoing terraform apply operations, if others also try for the same, it can corrupt our state file.

By default S3 backend doesnot supports terraform state file lock.

### Integrating Dynamo DB with S3 backend for state locking

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

__Move__

- The `terraform state mv` command is used to move items in a Terraform state.
- This command is used in many cases in which you want to rename an existing resource without destroying and recreating it.
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

We want to change the name from myec2 to webapp

```
resource "aws_instance" "myec2" {
    ami = "ami-00f7e5c52c0f43726"
    instance_type = "t2.micro"
}
```

Terraform will now try to destroy the resource and recreate it. This is something which would not want always.

We can use terraform state move command here

```
terraform state mv aws_instance.myec2 aws_instance.webapp
```

Terraform will now not show to destroy the resource and recreate it.


__Pull__

The `terraform state pull` command is used to manually download and output the state from remote state. This command also works with local state.

This is useful for reading values out of state (potentially pairing this command with something like `jq` ). 


__Push__

The `terraform state push` command is used to manually upload a local state file to remote state.

This command should rarely be used.

__Remove__

We can use `terraform state rm` in the less common situation where you wish to remove a binding to an existing remote object without first destroying it, which will effectively make Terraform "forget" the object while it continues to exist in the remote system.

```
terraform state rm aws_instance.myec2
```

__Show__

The `terraform state show` command is used to show the attributes of a single resource in the Terraform state.

```
terraform state show aws_instance.myec2
```

# Import existing resource using Terraform Import 

Terraform is able to import existing infrastructure. This allows you take resources you've created by some other means and bring it under Terraform management.

The current implementation of Terraform import can only import resources into the state. It does not generate configuration. 

Because of this, prior to running `terraform import` it is necessary to write manually a `resource` configuration block for the resource, to which the imported object will be mapped.


Manually write the resource configuration block for the resouce you wish to import
```
resource "aws_instance" "myec2" {
    ami = "ami-00f7e5c52c0f43726"
    instance_type = "t2.micro"
    tags {
        Name = "manual"
    }
}
```

Run terraform import command 
```
terraform import aws_instance.myec2 <instanceid>
```
