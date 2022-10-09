# Security Primer

## Access & Secret Keys the Right Way in Providers

- It is not recommended to provide `access_key` and `secrect_key` inside `providers` block in plain text.
- If we have aws cli and we have configured aws cli using `aws configure` then we donot need to provide and `access_key` and `secrect_key` inside `providers` block.
- aws cli stores the credentials on path `.\.aws\credentials` in plain text
    ```PowerShell
    PS C:\Users\user> cat .\.aws\credentials
    [default]
    aws_access_key_id = XXXXXXXXXXXXXXXXXXXX
    aws_secret_access_key = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    PS C:\Users\user> cat .\.aws\config
    [default]
    region = us-west-2
    ```

---
# Terraform Provider UseCase - Resources in Multiple Regions

## Single Provider Multiple Configuration

- Usually we use `aws-region` parameter within the `provider` block
- This means that resources would be created in the region specified in the `provider` block

Some Challenging usecases
- Deploy resources in different regions
- Deploy resources in different accounts

## We can use `alias` to define multiple configurations for the same provider

To create multiple configurations for a given provider, include multiple `provider` blocks with the same `provider` name. For each additional non-default configuration, use the `alias` meta-argument to provide an extra name segment. For example:

`providers.tf`
```
provider "aws" {
  region = "us-west-1"
}

provider "aws" {
  alias   = "mumbai"
  region  = "ap-south-1"
}
```

We can now reference these `provider` configurations on `resource` configuration block `<provider-name>.<alias-value>`

```
resource "aws_eip" "myeip" {

}

resource "aws_eip" "myeip01" {
  vpc       = "true"
  provider  = "aws.mumbai"
}
```

Now second `aws_eip` resource `myeip01` will be deployed in `ap-south-1` region ad this resource is poining to `provider` `aws` with `alias` `mumbai` i.e. `aws.mumbai`

---

# Multiple AWS Profiles with Terraform Providers

UseCase: Launching multiple resources in differnet accounts

we can have multiple aws profiles and credentials/access_keys  for all profiles are available in `.\.aws\credentials` file

```PowerShell
PS C:\Users\user> cat .\.aws\credentials
[default]
aws_access_key_id = XXXXXXXXXXXXXXXXXXXX
aws_secret_access_key = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

[account02]
aws_access_key_id = XXXXXXXXXXXXXXXXXXXX
aws_secret_access_key = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

aws cli has `--profile` flag where we can specify the profile and aws cli will refernce the credentials/access_keys of specified `profile`

```
aws s3 ls --profile account02
```

We can also configure terraform to use different profiles, within the `provider` block we can give name of `profile` which we want to target

```
# Uses credentials for default profile
provider "aws" {
  region = "us-east-1"
}

# Uses credentials for account02 profie
provider "aws" {
  alias  = "aws02"
  region = "us-west-2"
  profile = "account02"     # Targets `account02` aws profile credentials
}

# Following resource uses default "aws" provider 
resource "aws_eip" "myeip" {
    vpc = "true"
}

# Following resource uses "aws" alias "west" provider 
resource "aws_eip" "myeipwest" {
    vpc = "true"
    provider = aws.aws02
}
```

## Terrafrom & Assume Role with AWS STS

Note: "Terraform & Assume Role with AWS STS" is beyond the scope of official Terraform exams.

Identity Account has Single set of 
- Username & Password
- Access & Secret Keys

Using Identity Account we can assume role to access multiple AWS accounts
- Account A
- Account B
- Account C

AWS User Assuming roles

- AWS IAM Roles - ablabs-sts
  - Permissions
    - AdministratorAccess
    - AmazonS3FullAccess
- AWS IAM User - sts-user
  - access and secret key
  - Permissions
    - AssumeRole (ablabs-sts)
      ```json
      {
        "version": "",
        "Statement": [
          {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::641213165464:role/ablabs-sts"
          }

        ]
      }
      ```

In above example AWS IAM user `sts-user` has a single permission to assume `ablabs-sts` role. that means `sts-user` will first has to AssumeRole and then using Role credentials `sts-user` can work with S3 buckets.


Assume role using `aws cli`, where your credentials donot have access however you can assume role to perform certain operations
```
aws sts assume role --role-arn arn:aws:iam:641213165464:role/ablabs-sts --role-session-name ablabs-test
```
above command will generate `credentials` 
- `AccessKeyId`
- `SecretAccessKey`
- `SessionToken`

we can also configure terraform `provider` to `assume-role` for creating a resource

```
provider "aws" {
  region = "us-west-2"
  assume_role {
      role_arn = "arn:aws:iam:641213165464:role/ablabs-sts"
      session_name = "ablabs-test"
  }
}

resource "aws_eip" "myeip" {
    vpc = "true"
}
```

by `assuming-role` in aws we can also have access to multiple accounts

---

# Sensitive Paramter

While managing infrastructure with terraform, it is likely that you will see some sensitive information embedded in code.

When working with a field that contains information likely to be considered sensitive, it is best to set the `sensitive` property on its schema to `true`.

```
locals {
  db_password = {
    admin = "P@55w0rD"
  }
}

output "db_password" {
    value     = local.db_password
    sensitive = true
}
```

- setting `sensitive` value to "true" will prevent the field's values from showing up in CLI output and in Terraform cloud
- setting `sensitive` value to "true" will not encrypt or obscure the value in the state. 

---

# HashiCorp Vault

- HashiCorp Vault allows organizations to securely store secrets like tokens, passwords, certificates along with access management for protecting secrets
- One common challenges for organizations is "Secrets Management"
  - Secrets can include, database passwords, AWS access/secret keys, API Tokens, encryption keys and others

## Dynamic Secrets
- Secrets to access database, cloud accounts can be generated dynamically which are short lived and rotated. Existing secret can be renewed or new secret can be generated when existing secret expires.

---
# Terraform and Vault Integration - Vault Provider

- The Vault provider allows Terraform to read from, write to, and configure HashiCorp Vault
- We can inject vault secrets in Terraform

  ```
  provider "vault" {
    address = "http://127.0.0.1:8200"
  }

  data "vault_generic_secret" "demo" {
    path = "secret/db-creds"
  }

  output "vault_secrets" {
    value     = data.vault_generic_secret.demo.data_json
    sensitive = "true"
  }
  ```
- We can also configure valut to fetch AWS credentials (Access Key and Secret Key) which then can be used by terraform to deploy infrastructure

---