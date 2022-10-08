# Deploying Infrastructure with Terraform

## Create EC2 instace with Terraform

- How will you authenticate to AWS
- Which region in AWS
- Which resource

|                   |                             | 
| ----------------- | --------------------------- | 
| Terraform Registry | https://registry.terraform.io/ |
| Browse Providers | https://registry.terraform.io/browse/providers | 
| AWS Provider | https://registry.terraform.io/providers/hashicorp/aws/latest | 
| AWS Provider Docs | https://registry.terraform.io/providers/hashicorp/aws/latest/docs |


## Authenticate with Static Credentials

### Create IAM User in AWS

| | | 
| - | - |
| User name | terraform |
| Credential type | Access key - Programmatic access |  
| Permissions | Attach Administrator Access policy | 

Note down 
- Access key ID
- Secret access key 

### Create terraform configuration file

```
first-ec2.tf
```

- `provider` block for AWS

```hcl
provider "aws" {
  region = "us-west-2"
}
```

- Set environment variables for authentication

```bash
export AWS_ACCESS_KEY_ID="anaccesskey"
export AWS_SECRET_ACCESS_KEY="asecretkey"
export AWS_DEFAULT_REGION="us-west-2"
```

- Check docs for ec2 instance

  <https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance>


- `resource` block

```hcl
resource "aws_instance" "myec2" {
  ami = "ami-00f7e5c52c0f43726"
  instance_type = "t2-micro"
}
```

- `terraform init`

```bash
terraform init

Initializing the backend...

Initializing provider plugins...
- Finding latest version of hashicorp/aws...
- Installing hashicorp/aws v4.34.0...
- Installed hashicorp/aws v4.34.0 (signed by HashiCorp)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

- `terraform plan`
  - generates the execution plan
  - indicates Resource actions
  - Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply" now.
- `terraform apply`
  - Enter `yes` when asked to perform the actions
    ```bash
    ...
    Plan: 1 to add, 0 to change, 0 to destroy.

    Do you want to perform these actions?
      Terraform will perform the actions described above.
      Only 'yes' will be accepted to approve.

      Enter a value: yes

    aws_instance.web: Creating...
    aws_instance.web: Still creating... [10s elapsed]
    aws_instance.web: Still creating... [20s elapsed]
    aws_instance.web: Still creating... [30s elapsed]
    aws_instance.web: Creation complete after 34s [id=i-0a2f5b4bf96c2e2ad]
    ```
  

## Providers & Resources

- Providers are plugins that implement resource types.
  - Terraform Providers: <https://registry.terraform.io/browse/providers>
- Terraform supports multiple providers
- Depending on what type of infrastructure we want to launch, we have to use appropriate providers accordingly.
  - aws
  - azure
  - google cloud platform
  - kubernetes 
  - oracle cloud infrastructure 
  - github


### Important Update - Providers in Newer Version of terrafrom (0.13 and later)

From 0.13 onwards, Terraform requires explicit source information for any providers that are not HashiCorp-maintained, using a new syntax in the required_providers netsted block inside the terraform configuration block

Hashicorp Maintained provider
```hcl
provider "aws" {
  region = "us-west-2"
  access_key = "PUT-YOUR-ACCESS-KEY-HERE"
  secret_key = "PUT-YOUR-SECRET-KEY-HERE"
}
```

Non-HashiCorp Maintained provider
```hcl
terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/dgitalocean"
    }
  }
}

provider "digitalocean" {
  token = "PUT-YOUR-TOKEN-HERE"
}
```

> From terraform 0.13 owards it is recommended to use latest format and provide required_providers under terraform configuration block

### Initialization Phase
- Upon adding a provider, it is important to run `terraform init` which will download plugins associated with the provider

Example :

- add azure provider
```hcl
provider "azurerm" {

}
```

- `terraform init` will detect the new provider specified and will download the approriate plugins

```bash
terraform init
```

### Resources

- Resources are the reference to the inividual services which the provider offers 

Example:
- resource aws_instance

```hcl
resource "aws_instance" "myec2" {
    ami = "ami-00f7e5c52c0f43726"
    instance_type = "t2.micro"
}
```

- resource aws_alb
- resource iam_user
- resource digitalocean_droplet
- resource github_repository

## `terraform destroy` Destoying Infrastructure with Terraform 

Approach 1
- `terraform destroy` allows us to destory all the resources that are created within the folder

```bash
terraform destroy
```

Approach 2
- `terraform destory` with `-target` flag allows us to destroy specify resource
- The `-target` flag can be used to focus Terraform's attention on only a subset of resources
  - combination of resource_type.local-resource-name
  - eg aws_instace.myec2 where aws_instance is resource type and myec2 is local resource name

```bash
terraform destroy -target aws_instance.myec2
```

Apraoch 3
- You can also comment out the resource block or delete the file and when you will do `terraform plan` you can see that terraform will now try to destroy that resource as terraform assumes that you no longer need that resource.

Example:
```hcl
/*
resource "aws_instance" "myec2" {
    ami = "ami-00f7e5c52c0f43726"
    instance_type = "t2.micro"
}
*/
```

# Terraform State file

- Terraform stores the state of the infrastructure that is being created from the terraform files (.tf) in `terraform.tfstate` file 
- This state allows terraform to map real world resource to your existing configuration
- If you manually remove the terraform state file terraform will now no longer has any information related to resources it created and when we do the terrafor plan and terraform apply, terraform will again try to create the new resources as per terrraform configuration file and will start managing the new resources.

## Desired state and Current State

- Terraform's primary function is to create, modify and destroy infrastructure resources to match the desired state described in a Terraform configuration

for example if we provide resource block for aws_instance terraform's job is to make sure that instance is avaialble in AWS i.e. desrired state.

- Current state is the actual state of a resource that is currently deployed.

for example your `aws_isntance` resource in terraform configuration is specified to have `instance_type` of `t2.micro` and you have created this instance using `terraform apply`. Now someone from your team modifies the `instance_type` from `t2.micro` to `t2.medium`. Now current state of your real world infrastructure is different from the desired state specified in terraform configuration file.

- Terraform tries to ensure that the deployed infrastructure is based on the desired state. 
- If there is difference between the current state and desired state, terraform plan presents the description of the changes necessary to achive the desired state.

i.e. for our example terrafor will now try to change back the instance type of our `aws_instance` resource from `t2.medium` back to `t2.micro` which we have specified in desired state in our terraform configuration file.

- `terraform refresh` command will fetch the current state of resource and will also update the state file to represent the current state of infrastructure. Some commands like terraform plan will do the terraform refresh internally.

>Note: Sometimes the changes in current state of an resource can force a replacement of a resourse i.e. terraform will destry and recreate that resource for you. for example if current state of aws_instance has `instance_type=t3.medium` which automatically changes property `ebs_optimised = true` and your desired state of aws_instance is conifgured as `instance_type=t2.micro` your next terraform apply will try to replace your resource as `ebs_optimised` property forces replacement. This makes very important to read the terraform plan very carefully before doing a terraform apply.


# Challenges with current state

- Terraform always tries to achieve the desired state.

Let's take a Case:

- lets say you have EC2 instance running based on below configuration -
```
resource "aws_instance" "myec2" {
    ami = "ami-00f7e5c52c0f43726"
    instance_type = "t2.micro"
}
```
- When we check the AWS console we can see that current security group attached to our EC2 instance is `default`. You can also observe this in `terraform.tfstate` file

- Lets say we change the security group from `default` to `custom` via AWS console. Now you do terraform refresh and you can observe in `terraform.tfstate` file that security group is now changed from `default` to `custom`.

- Now what will terraform do when we re run `terraform apply` ? you would generally think terraform will change back the security group back to `default` but the answer is no terraform will not do that. When we run `terraform plan` we can observe the output `No  changes. Infrastructure is up-to-date.`  but why ? the answer is terraform tries to match Desired state described in terraform configuration. `Terraform's primary function is to create, modify and destroy resource to match the __desired state described in a terraform configuration__.`

- In our terraform configuration we never described security group should be `default`. Security group doesnot come as part of desired state. So even if we modify the infrastructure that are not part of desrired state, `terraform plan` will not show us any details to revert those changes.

- This is why it is recommended to specify all the important configuration that you wish to have in your resource as part of terraform configuration so that it always matches the desired state whenever you run `terraform plan` in the future.

# Terraform Provider Versioning

- `first-ec2.tf` file creates the EC2 resource
- terraform makes use of aws __provider plugins__ that have been initialized
- provider plugin interacts with AWS (API interactions) 
- provider plugins are released separately from terraform itself, they have different set of version numbers.
- we end up have Terrafrom versions as well as Provider versions which are developed separately.
- This versioning has its own set of challenges, add upgraded versions can have breaking changes.

## Explicitly setting provider version

- For terraform production environments its important to explicityly set the provider version.

- During terraform init, if version argument is not specified, the most recent provider will be dowloaded during initialization.
- For production use, you should constrain the acceptable provider versions via configuration, to ensure that new versions with breaking changes will not be automatically installed.

```
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
```

### Arguments for specifyig provider version

- There are multiple ways for specifying the version of provider.

| Version Number Arguments | Description |
|--------------------------|-------------|
| >=1.0 | Greater than equal to the version |
| <=1.0 | Less than equal to the version |
| ~>2.0 | Any version in 2.X range |
| >=2.10, <=2.30 | Any version between 2.10 and 2.30 |

Example: following code specifies specific provider version

```
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "3.68.0"
    }
  }
}

provider "aws" {
  # Configuration options
}
```

- `terraform init` downloads the provider specified in terraform configuration, this also generates a dependency lock file `.terraform.lock.hcl` -

  ```
  Terraform has created a lock file .terraform.lock.hcl to record the provider selections it made above. Include this file in your version control repository so that Terraform can guarantee to make the same selections by default when
  you run "terraform init" in the future.
  ```

- since we have this dependency lock file generated when we try to change the version in our configuration file and do `terraform init` it might fail as lock file helps us to stick to a version constraint that is being defined in our terraform configuration and lock file blocks the version change.

- in order to change the provider version and update the lock file you can use `terraform init` command with `-upgrade` flag
  ```
  terraform init -upgrade
  ```
  
  > Note: You can also manually remove/delete `.terraform.lock.hcl` file, which will then allow you to do successful provider version change using `terrform init` and will generate a new lock file.

### terraform dependency lock file

- terraform dependency lock file allows us to lock to a specific version of the provider.
- If a particular provider already has a selection recorded in the lock file, Terraform will always re-select that version for installation, even if a newer version has become available.
- you can override this behaviour by adding `-upgrade` option when you run `terraform init`

`.terraform.lock.hcl`
```
# This file is maintained automatically by "terraform init".
# Manual edits may be lost in future updates.

provider "registry.terraform.io/hashicorp/aws" {
  version     = "2.70.0"
  constraints = "~> 2.0"
  hashes = [
    "h1:fx8tbGVwK1YIDI6UdHLnorC9PA1ZPSWEeW3V3aDCdWY=",
    "zh:01a5f351146434b418f9ff8d8cc956ddc801110f1cc8b139e01be2ff8c544605",
    "zh:1ec08abbaf09e3e0547511d48f77a1e2c89face2d55886b23f643011c76cb247",
    "zh:606d134fef7c1357c9d155aadbee6826bc22bc0115b6291d483bc1444291c3e1",
    "zh:67e31a71a5ecbbc96a1a6708c9cc300bbfe921c322320cdbb95b9002026387e1",
    "zh:75aa59ae6f0834ed7142c81569182a658e4c22724a34db5d10f7545857d8db0c",
    "zh:76880f29fca7a0a3ff1caef31d245af2fb12a40709d67262e099bc22d039a51d",
    "zh:aaeaf97ffc1f76714e68bc0242c7407484c783d604584c04ad0b267b6812b6dc",
    "zh:ae1f88d19cc85b2e9b6ef71994134d55ef7830fd02f1f3c58c0b3f2b90e8b337",
    "zh:b155bdda487461e7b3d6e3a8d5ce5c887a047e4d983512e81e2c8266009f2a1f",
    "zh:ba394a7c391a26c4a91da63ad680e83bde0bc1ecc0a0856e26e9d62a4e77c408",
    "zh:e243c9d91feb0979638f28eb26f89ebadc179c57a2bd299b5729fb52bd1902f2",
    "zh:f6c05e20d9a3fba76ca5f47206dde35e5b43b6821c6cbf57186164ce27ba9f15",
  ]
}
```

When should we swtich/upgrade provider version ?
- It depends, there might be some new service that will only be supported in newer provider versions, so this can be one of the criteria for upgrading provider versions.
- provider versions can have breaking changers hence proper testing is required before upgrading provider version in production as it might break things unexpectedly.

---
