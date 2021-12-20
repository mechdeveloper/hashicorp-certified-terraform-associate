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

## Resources in multiple regions

`alias`: Multiple Provider Configurations

We can optionally define multiple configurations for the same provider, and select which one to use on a per-resource or per-module basis. The primary reason for this is to support multiple regions for a cloud platform; other examples include targeting multiple Docker hosts, multiple Consul hosts, etc.

To create multiple configurations for a given provider, include multiple `provider` blocks with the same provider name. For each additional non-default configuration, use the `alias` meta-argument to provide an extra name segment. For example:

```
# The default provider configuration; resources that begin with `aws_` will use
# it as the default, and it can be referenced as `aws`.
provider "aws" {
  region = "us-east-1"
}

# Additional provider configuration for west coast region; resources can
# reference this as `aws.west`.
provider "aws" {
  alias  = "west"
  region = "us-west-2"
}

# Following resource uses default "aws" provider 
resource "aws_eip" "myeip" {
    vpc = "true"
}

# Following resource uses "aws" alias "west" provider 
resource "aws_eip" "myeipwest" {
    vpc = "true"
    provider = aws.west
}
```

## Multiple AWS profiles with Terraform Providers

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

aws cli has `--profile` flag where we can specify the profile and aws cli will refernce the credentials/access_keys of specified profile

```
aws s3 ls --profile account02
```

We can also configure terraform to use different profiles 

```
# Uses credentials for default profile
provider "aws" {
  region = "us-east-1"
}

# Uses credentials for account02 profie
provider "aws" {
  alias  = "aws02"
  region = "us-west-2"
  profile = "account02"
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

Identity
Single set of 
- Username & Password
- Acces & Secret Keys

Can access multiple AWS accounts
- Account A
- Account B
- Account C


Assume role using aws cli, where your credentials donot have access however you can assume role to perform certain operations
```
aws sts assume role --role-arn arn:aws:iam:641213165464:role/ablabs-sts --role-session-name ablabs-test
```
above command will generate credentials 
- `AccessKeyId`
- `SecretAccessKey`
- `SessionToken`

we can also configure terraform to use assumerole for creating a resource
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

## Sensitive Paramter

While managing infrastructure with terraform, it is likely that you will see some sensitive information embedded in code.

When working with a field that contains information likely to be considered sensitive, it is best to set the `sensitive` property on its schema to `true`.

```
output "db_password" {
    value = aws_db_instance.db.password
    sensitive = true
}
```

setting sensitive value to "true" will prevent the field's values from showing up in CLI output and in Terraform cloud

It will not encrypt or obscure the value in the state. 
