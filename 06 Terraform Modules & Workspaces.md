# Terraform Modules

`DRY` Don't Repeat Yourself, is a priciple in software development aimed at reducing repetition of of software patterns.

Modules are containers for multiple resources that are used together. A module consists of a collection of .tf and/or .tf.json files kept together in a directory.

Modules are the main way to package and reuse resource configurations with Terraform.

## The Root Module

Every Terraform configuration has at least one module, known as its root module, which consists of the resources defined in the `.tf` files in the main working directory.

## Child Modules

A Terraform module (usually the root module of a configuration) can call other modules to include their resources into the configuration. A module that has been called by another module is often referred to as a child module.

Child modules can be called multiple times within the same configuration, and multiple configurations can use the same child module.

## Published Modules

In addition to modules from the local filesystem, Terraform can load modules from a public or private registry. This makes it possible to publish modules for others to use, and to use modules that others have published.

### Terraform Registry

The Terraform Registry <https://registry.terraform.io/browse/modules> hosts a broad collection of publicly available Terraform modules for configuring many kinds of common infrastructure. These modules are free to use, and Terraform can download them automatically if you specify the appropriate source and version in a module call block.

Also, members of your organization might produce modules specifically crafted for your own infrastructure needs. Terraform Cloud and Terraform Enterprise both include a private module registry for sharing modules internally within your organization.

#### Verified Modules in Terraform Registry
Within Terraform registry you can find verified modules that are maintained by various third party vendors.

Verified modules are reviewd by HashiCorp and actively maintained by contributors to stay up-to-date and compatible with both Terraform and their respective providers.

The blue verificaton badge appears next to modules that are verified.

Module verification is currently a manual process restricted to a small group of trusted HashiCorp partners.

Verified Module Example - <https://registry.terraform.io/modules/terraform-aws-modules/ec2-instance/aws/latest>

## Using Modules

### Module Blocks

__Calling a Child Module__

To call a module means to include the contents of that module into the configuration with specific values for its input variables. Modules are called from within other modules using `module` blocks:

```
module "servers" {
  source = "./app-cluster"

  servers = 5
}
```

A module that includes a module block like this is the calling module of the child module.

The label immediately after the `module` keyword is a local name, which the calling module can use to refer to this instance of the module.

Within the block body are the arguments for the module. Module calls use the following kinds of arguments:

- The `source` argument is mandatory for all modules.
- The `version` argument is recommended for modules from a registry.
- Most other arguments correspond to input variables defined by the module. (The `servers` argument in the example above is one of these.)
- Terraform defines a few other meta-arguments that can be used with all modules, including `for_each` and `depends_on`.

__Source__

All modules require a `source` argument, which is a meta-argument defined by Terraform. Its value is either the 
- path to a local directory containing the module's configuration files, or a 
- remote module source that Terraform should download and use.

The same source address can be specified in multiple module blocks to create multiple copies of the resources defined within, possibly with different variable values.

After adding, removing, or modifying `module` blocks, you must re-run `terraform init` to allow Terraform the opportunity to adjust the installed modules. By default this command will not upgrade an already-installed module; use the `-upgrade` option to instead upgrade to the newest available version.

Local Paths
```
module "consul" {
  source = "./consul"
}
```

Terraform Registry
```
module "consul" {
  source = "hashicorp/consul/aws"
  version = "0.1.0"
}
```

__Version__

When using modules installed from a module registry, we recommend explicitly constraining the acceptable version numbers to avoid unexpected or unwanted changes.

Use the version argument in the module block to specify versions:

```
module "consul" {
  source  = "hashicorp/consul/aws"
  version = "0.0.5"

  servers = 3
}
```

The version argument accepts a version constraint string. Terraform will use the newest installed version of the module that meets the constraint; if no acceptable versions are installed, it will download the newest version that meets the constraint.

Version constraints are supported only for modules installed from a module registry, such as the public Terraform Registry or Terraform Cloud's private module registry. Other module sources can provide their own versioning mechanisms within the source string itself, or might not support versions at all. In particular, modules sourced from local file paths do not support `version`; since they're loaded from the same source repository, they always share the same version as their caller.

__Meta-arguments__

Along with `source` and `version`, Terraform defines a few more optional meta-arguments that have special meaning across all modules 

- `count` - Creates multiple instances of a module from a single `module` block.
- `for_each` - Creates multiple instances of a module from a single `module` block.
- `providers` - Passes provider configurations to a child module. If not specified, the child module inherits all of the default (un-aliased) provider configurations from the calling module.
- `depends_on` - Creates explicit dependencies between the entire module and the listed targets.

In addition to the above, the `lifecycle` argument is not currently used by Terraform but is reserved for planned future features.

Example - Reference a local path module

- `modules` folder
  - `ec2.tf`

- `projects` folder
  - `ProjectA` folder
    - `myec2.tf`
      ```
      # Rererences module in local path
      module "ec2module" {
        source = "../../modules/ec2"
      }
      ```


- `terraform init` is required to initalize modules.
  ```
  terraform init
  ```

- `terraform plan` will now show the resources via modules
  ```
  terraform plan
  ```

Example - Reference a verified module from terraform registry

```
provider "aws" {
    region = "us-west-2"
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  name = "single-instance"

  ami                    = "ami-00f7e5c52c0f43726"
  instance_type          = "t2.micro"
  
  # make sure subnet_id is correct from aws console
  subnet_id              = "subnet-eddcdzz4" 

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
```

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
      - `terraform.tfstate` for dev workspace
    - `prod` folder
      - `terraform.tfstate` for prod workspace
