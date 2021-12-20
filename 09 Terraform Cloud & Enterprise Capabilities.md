# Terraform cloud 

Terraform cloud manages Terraform runs in a consistent and reliable environment with various features like access controls, private registry for sharing modules, policy controls and others.

# Sentinel

Sentinel is an embedded policy as a code framework integrated with the HashiCorp Enterprise products.

It enables fine-grained, logic-based policy decisions, and can be extended to use information from external sources.

Note: Sentinel policies are paid feature

terraform plan --> sentinel checks --> terraform apply

High level structure

- Workspace
  - Policy Sets
    - Policy 
      - `Block EC2 with tags`


Sentinel Documentation

<https://docs.hashicorp.com/sentinel/terraform/>

Sentinel Policy :

Example: All AWS instances must have a tag

```
import "tfplan"
 
main = rule {
  all tfplan.resources.aws_instance as _, instances {
    all instances as _, r {
      (length(r.applied.tags) else 0) > 0
    }
  }
}
```

# Terraform Cloud - Backend Operation Types

The remote backend stores terraform state and may be used to run operations in Terraform Cloud.

Terraform cloud can also be used with local operations, in which case only state is stored in the Terraform Cloud backend.

## Remote Operations 

When using full remote operations, operations like terraform plan or terraform apply can be executed in Terraform Cloud's run environment, with output streaming to the local terminal.

## Implementing Remote Backend Operations in Terraform Cloud

Documentation

<https://www.terraform.io/docs/backends/types/remote.html>

```
terraform login
```
terraform will store the token in local machine in plain text

`backend.hcl`
```
workspaces { name = "terraform-remote-backend" }
hostname     = "app.terraform.io"
organization = "ashishbaghel"
```

```
terraform init --backend-config=backend.hcl
```

```
terraform plan
```

