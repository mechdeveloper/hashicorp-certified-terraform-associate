# DRY Principle
`DRY` Don't Repeat Yourself, is a priciple in software development aimed at reducing repetition of software patterns.

We can centralize the terraform resources and can call out from TF files whenever required.

---
# Implementing EC2 module with Terraform

Folder Structure
```
modules
|..ec2
   |..ec2.tf
projects
|..project-a
   |..myec2.tf
   |..providers.tf
```

`modules/ec2/ec2.tf`
```
resource "aws_instance" "myec2" {
    ami = "ami-08e2d37b6a0129927"
    instance_type = "t2.micro"
}
```

`proejcts/project-a/myec2.tf`
```
module "ec2module" {
    source = "../../modules/ec2"
}
```

`terraform init` is required to initialize modules, backend, provider plugins
```
terraform init
```

---
# Variables and Terraform Modules


Folder Structure
```
modules
|..ec2
   |..ec2.tf
   |..variables.tf
projects
|..project-a
   |..myec2.tf
   |..providers.tf
```

`modules/ec2/ec2.tf`
```
resource "aws_instance" "myec2" {
    ami = "ami-08e2d37b6a0129927"
    instance_type = var.instance_type   # referencing variable
}
```

`modules/ec2/variables.tf`
```
variable "instance_type" {
  default = "t2.micro"
}
```

`proejcts/project-a/myec2.tf`
```
module "ec2module" {
    source = "../../modules/ec2"
    instance_type = "t2.large"
}
```

`terraform plan` will now pickup the value `t2.large` specified in project as variables allow users to override them.
```
terraform plan
...
  + instance_type                        = "t2.large"
...
```

---

# Using Locals with Modules

- Instead of variables, `locals` to assign the values.
- `locals` can be used to prevent users from overriding values for your terraform modules


```
resource "aws_security_group" "ec2-sg" {
  name = "myec2-sg"

  ingress {
    description   = "Allow Inbound from Secret Application"
    from_port     = local.app_port
    to_port       = local.app_port
    protocol      = "tcp"
    cidr_blocks   = ["0.0.0.0/0"]
  }
}

locals {
  app_port = 8444
}
```
---
# Referencing Module Outputs

- Output values make information about your infrastructure available on the command line, and can expose information for other Terraform configurations to use.

## Accessing Child Module Outputs
In a parent module, outputs of child modules are available in expressions as `module.<MODULE_NAME>.<OUTPUT_NAME>`

Example: referencing output in a root module from a child module
```
moduel "sgmodule" {
  source = "../../modules/sg"
}

resource "aws_instance" "web" {
    ami             = "ami-08e2d37b6a0129927"
    instance_type   = "t3.micro"
    vpc_security_group_ids = [module.sgmodule.sg_id]
}
```

`modules/sg/sg.tf` - child module with output
```
...

output "sg_id" {
  value = aws_security_group.ec2-sg.arn
}
```

---
# Terraform Registry

The Terraform Registry <https://registry.terraform.io/browse/modules> hosts a broad collection of publicly available Terraform modules for configuring many kinds of common infrastructure. These modules are free to use, and Terraform can download them automatically if you specify the appropriate source and version in a module call block.

Also, members of your organization might produce modules specifically crafted for your own infrastructure needs. Terraform Cloud and Terraform Enterprise both include a private module registry for sharing modules internally within your organization.

## Verified Modules in Terraform Registry
- Within Terraform registry you can find verified modules that are maintained by various third party vendors.

- Verified modules are reviewd by HashiCorp and actively maintained by contributors to stay up-to-date and compatible with both Terraform and their respective providers.

- The blue verificaton badge appears next to modules that are verified.

- Module verification is currently a manual process restricted to a small group of trusted HashiCorp partners.

- Verified Module Example - <https://registry.terraform.io/modules/terraform-aws-modules/ec2-instance/aws/latest>

## Using Registry Module in Terraform

- To use Terraform Registry module within the code, we can make use of the source argument that contains the module path.
- Below code references to the EC2 Instance module within terraform registry

  ```hcl
  module "ec2-instance" {
    source = "terraform-aws-modules/ec2-instance/aws"
    version = "4.1.4"

    for_each = toset(["one", "two", "three"])

    name = "instance-${each.key}"

    ami                    = "ami-08e2d37b6a0129927"
    instance_type          = "t2.micro"
    subnet_id              = "subnet-eddcdzz4"

    tags = {
      Terraform   = "true"
      Environment = "dev"
    }
  }
  ```
---
# Publishing Modules in Terraform Registry

- Anyone can publish and share modules on the Terraform Registry
- Published modules support versioning, automatically generate documentation, allow browsing version histories, show example and READMEs, and more

## Requirements for publishing module

| Requirement | Description |
|-|-|
| Github | The module must be on GitHub and must be a public repo. This is only a requirement for the public registry |
| Named | Module repositories must use this three-par name format `terraform-<PROVIDER>-<NAME>` |
| Repository Description | The GitHub repository description is used to populate the short description of the module |
| Standard module structure | The module must adhere to the standard module structure |
| x.y.z tags for releases | The registry uses tags to identify module versions. Release tag names must be a semantic version, which can optionally be prefixed with a v. For example v1.0.4 and 0.9.2 |

## Standard Module Structure

The standard module structure is a file and directory layout that is recommended for reusable modules distributed in separate repositories


`minimal-module`
```
.
|-- README.md
|-- main.tf
|-- variables.tf
|-- outputs.tf
```

`complete-module`
```
.
|-- README.md
|-- main.tf
|-- variables.tf
|-- outputs.tf
|-- ...
|-- modules/
|  |-- nestedA/
|  |   |-- README.md
|  |   |-- main.tf
|  |   |-- variables.tf
|  |   |-- outputs.tf
|  |-- nestedB/
|  |-- .../
|-- examples/
|  |-- exampleA/
|  |   |-- main.tf
|  |-- exampleB/
|  |-- .../
```

--- 
# Terraform Workspaces

Terraform allows us to have multiple workspaces, with each of the workspace we can have different set of environment variables associated

```
terraform workspace
```

Display current workspace
```
terraform workspace show
```

Create workspace and switch to it 
```
terraform workspace new dev
```
```
terraform workspace new prod
```

List available workspaces
```
terraform workspace list
```

Switch workspace 
```
terraform workspace select dev
```

Define Variables in terraform specific to workspace 
```
provider "aws" {
    region = "us-west-2"
}

resource "aws_instance" "myec2" {
    ami = "ami-00f7e5c52c0f43726"
    instance_type = lookup(var.instance_type, terraform.workspace)
}

variable "instance_type" {
  type = map
  default = {
    default = "t2.nano"
    dev     = "t2.micro"
    prod    = "t2.large"
  }
}
```

Terrafrom maintains `.tfstate` file for each workspace inside `terraform.workspace.d` folder. Default workspace file is always present in root folder `terraform.tfstate`. 

Following will be the folder structure
- `root` folder
  - `terraform.tfstate` file for default workspace
  - `terraform.workspace.d` folder
    - `dev` folder
      - `terraform.tfstate` for `dev` workspace
    - `prod` folder
      - `terraform.tfstate` for `prod` workspace

---
