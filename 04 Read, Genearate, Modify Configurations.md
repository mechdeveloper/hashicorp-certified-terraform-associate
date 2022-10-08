# Terraform in detail

## Attributes & Output Values in Terraform

- Attributes and Output values are very important topics and are used quite often while managing production infrastructure using terraform.
- Terraform has capability to output the attribute of a resource with __output values__ 

Example: 
```
ec2_public-ip       = 54.148.212.83
bucket_identifier   = ablabs-attribute-test-001.s3.amazonaws.com
```

### Attributes are important 

- Terraform documentation of a resource for eg `aws_eip` has a section called __Attributes Reference__ which contains a list of attributes which we can output within our terraform code.

- An output attribute can be used for user reference and can also act as input to other resources being created via terraform.

- Example usecase: After EIP gets created, it's IP address should automatically get whitelisted in security group.


- Resource blocks have two strings before the block: 
  - resource type and 
  - resource name
- Resource can be referenced by using:
  - `<resourcetype>.<resourcename>`
  - for example following resource block can be referenced as `aws_s3_bucket.mys3`
    ```
    resource "aws_s3_bucket" "mys3" {
      bucket = "ablabs-attribute-test-001"
    }
    ```
- Attributes specific to a resource can be referenced as 
  - `<resourcetype>.<resourcename>.<resourceattribute>`
- Example: output specific attribute `bucket_domain_name` of s3 bucket resource
  - `<resourcetype> = aws_s3_bucket`
  - `<resourcename> = mys3`
  - `<resourceattribute> = bucket_domain_name`
  ```
  output "mys3bucket-domain-name" {
    value = aws_s3_bucket.mys3.bucket_domain_name
  }
  ```

  Example: 
  ```
  # aws resource - s3 bucket
  resource "aws_s3_bucket" "mys3" {
    bucket = "ablabs-attribute-test-001"
  }
  # above resource can be referenced by using 
  # `aws_s3_bucket.mys3`
  # where `aws_s3_bucket` is `resourcetype` and `mys3` is `resourcename`

  output "mys3bucket-domain-name" {
    value = aws_s3_bucket.mys3.bucket_domain_name
  }
  ```

  Terraform configuration example (output all attributes of a resource vs output single attribute of a resource) :
  ```
  # aws resource - s3 bucket
  resource "aws_s3_bucket" "mys3" {
    bucket = "ablabs-attribute-test-001"
  }

  # output all atrribute values associated with s3 bucket resource
  output "mys3bucket" {
    value = aws_s3_bucket.mys3
  }

  # output specific attribute of s3 bucket resource
  output "mys3bucket-domain-name" {
    value = aws_s3_bucket.mys3.bucket_domain_name
  }
  ```

- Terraform state file `terraform.tfstate` also has a dedicated section of `outputs` 
- Structure of `terraform.tfstate` file
  ```
  {
    "version": 4,
    "terraform_version": "1.0.11",
    "serial": 16,
    "lineage": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "outputs": {...},
    "resources": [...]
  }
  ```

---

## Referencing Cross-Resource Attributes

### Direct Referencing
- elastic ip - assign it to an ec2 resource
  - for most cases directly referencing a resource and its attribute is the right apporach since 0.12 version onwards

  ```
  resource "aws_eip_association" "eip_assoc" {
      # direct referencing
      instance_id = aws_instance.myec2.id 
      allocation_id = aws_eip.lb.id
  }
  ```

### Block Style referencing `"${}"`
- elastic ip - add it to security group rule
  - block style `"${}"` approach to combine variable with a string
  ```
  resource "aws_security_group" "allow_tls" {
    name        = "ablabs-security-group"
    
    # Inbound
    ingress {
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"

      # block style referencing
      cidr_blocks      = ["${aws_eip.lb.public_ip}/32"]
    }
  }
  ```

---

## Terrafrom Variables

- Create a terraform file `variables.tf` which will act as central source of variable. We can reference these variables inside our terraform code.
- Define variables inside `variables.tf`
  ```
  variable "vpn_ip" {
    default = "116.50.30.20/32"
  }
  ```
- `vpn_ip` is variable name, `116.50.30.20/32` is value of `vpn_ip` variable
- Referencing a variable `var.<variablename>`
  ```
  resource "aws_security_group" "var_demo" {

    name        = "ablabs-variables"

    ingress {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [var.vpn_ip]
    }

    ingress {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = [var.vpn_ip]
    }

    ingress {
      from_port   = 53
      to_port     = 53
      protocol    = "tcp"
      cidr_blocks = [var.vpn_ip]
    }

  }
  ```
- Now if we want to change the value of `vpn_ip`,  we only need to change it in `variables.tf` file
- variables are important to make your code reusable and are used very extensively

---

## Approaches for Variable Assignment

- Variables in terraform can be assigned values in multiple ways. Some of these are 
  - Environment Variables
  - Command Line Flags
  - From File `terraform.tfvars`
  - Variable Defaults

### __Environment Variables__
  - you can set environment variables in format `TF_VAR_variablename`
  - set environment variable using windows commandline `cmd`
    ```cmd
    setx TF_VAR_instancetype m5.large
    ```
    - You can check the value of your environment variable in `cmd` command line by using 
      ```cmd
      echo %TF_VAR_instancetype%
      ```
    >Note: In Windows, Env variables will not reflect in existing `cmd` session, instead you need to start a new `cmd` session.
  - set environment variables using `bash`
    ```bash
    export TF_VAR_instancetype="t2.nano"
    ```
    - in Linux you donot need to restart the terminal session and you can check your environment variable in current sesssion 
      ```bash
      echo $TF_VAR_instancetype
      ```

### __Command Line flags `-var="variablename=variablevalue"`__
    ```bash
    terrafrom plan -var="instancetype=t2.small"
    ```

### __From File `terraform.tfvars`__
  
  ```
  instancetype="t2.large"
  ```

  - Note file name is `terraform.tfvars` is important here, it is recommended to use this name of file while defining the variable values you want to pass.

  - if you change the name of the file, for e.g. `custom.tfvars`, terraform by default will not see this file, however you can explicitly tell terraform to look into `custom.tfvars` file while running terraform cli command for eg 
     
     ```bash
     terraform plan -var-file="custom.tfvars"
     ```

### Variable Defaults

- if no explicit value is provided then the default value is used
    ```
    variable "instancetype" {
      default = "t2.micro"
    }
    ```

- If you have configured variables and not provided default value for your variable, neither you have passed any value via a `.tfvars` file or command line flag `-var` or via an environment variable, then __terraform will prompt for you to provide the variable value__ when running the cli command
  ```
  $ terraform plan
  var.instancetype
    Enter a value: 
  ```

>Note: Recommended way to provide variables is to use `terrafrom.tfvars` and also default values should ideally be provided when you are creating variables in terraform configuration using `variable` block.

---

## Datatypes for Terrafrom variables - `type` constraints

- Whenever we define a `variable` in terraform, We can also associate a specific `type` with that `variable`.
- The `type` argument in a `variable` block allows you to restrict the type of value that will be accepted as the value for a `variable`.
  ```
  variable "image_id" {
    type = string
  }
  ```
- If no `type` constraint is set then a value of any type is accepted.
- Data types 

  | `type` keyword | Description | 
  |--|--|
  | `string` | Sequence of Unicode characters representing some text, like `"hello"` |
  | `list` | Sequential list of values identified by their position. Starts with `0`, Example: `["mumbai", "singapore", "usa"]` | 
  | `map` | a group of values identified by named labels, like `{name = "Mabel, age=52}`| 
  | `number` | Example: `200` |
  | `bool` | Accepts bool values `true` or `false` |

- It is best practice to explicitly specify `type` of value that is expected for your variable

---

## Fetching values from `maps` and `list` in Terraform Variable
  - Fetching value from `maps` type, `var.variablename["key"]` -

    ```
    resource "aws_instance" "myec2" {
      ami = "ami-00f7e5c52c0f43726"
      instance_type = var.types["us-west-2"]
    }

    variable "types" {
      type = "map"
      default = {
        us-east-1 = "t2.micro"
        us-west-2 = "t2.nano"
        ap-south-1 = "t2.small"
      }
    }
    ```

- Fetching value from `list` type, `var.variablename[position-number]`

  ```
  resource "aws_instance" "myec2" {
    ami = "ami-00f7e5c52c0f43726"
    instance_type = var.instancelist[0]
  }

  variable "instancelist" {
    type = list
    default = ["m5.large","m5.xlarge","t2.medium"]
  }

  ```

---

## Count and Count Index

- The `count` parameter on resources can simplify configurations and let you scale resources by simply incrementing a number.
- Let's assume, you need to create two EC2 instances. One of the common approaches is to define two separate resource blocks for `aws_instance`. With `count` parameter, we can simply specify the count value and the resource can be scaled accordingly.
- Example of `count` parameter
  ```
  resource "aws_instance" "myec2" {
      ami = "ami-00f7e5c52c0f43726"
      instance_type = "t2.micro"
      count = 5
  }
  ```
- `count.index` - In resource blocks where count is set, an additional `count` object is available in expressions, so you can modify the configuration of each instance. This `count` object has one attribute: `count.index`, the distinct index number (starting with 0) corresponding to this instance.
- `count.index` allows us to fetch the index of each iteration in the loop.
- `count.index` Usecase: following example will create 3 iam users and the `name` attribute value for each iteration will  be fetched via list variable:
  ```
  variable "elb_names" {
    types = list
    default = ["dev-loadbalancer", "stage-loadbalancer", "prod-loadbalancer"]
  }

  resource "aws_iam_user" "lb" {
    name = var.elb_names[count.index]
    count = 3
    path = "/system/"
  }
  ```

---

## Conditional Expressions in Terraform
- a conditional expression uses the value of a bool expression to select one of the two values.
- Syntax of conditional expression:
  ```
  condition ? true_val : false_val
  ```
  - if conditon is `true` the the result is `true_val`. If condition is `false` then result is `false_val`

- Example : 
In below example, an `aws_instance` resource will be created based on the value of `istest` variable. If `istest` variable has `true` value then a dev `t2.micro` instance will be created else a prod `t2.large` instance will be created.

  `terraform.tfvars`
  ```
  istest = true
  ```

  `condition.tf`
  ```
  variable "istest" {}

  resource "aws_instance" "dev" {
      ami = "ami-00f7e5c52c0f43726"
      instance_type = "t2.micro"
      count = var.istest == true ? 1 : 0
  }

  resource "aws_instance" "prod" {
      ami = "ami-00f7e5c52c0f43726"
      instance_type = "t2.large"
      count = var.istest == false ? 1 : 0
  }
  ```

---

## Local Values in Terraform

- a local value assigns a name to expression, allowing it to be used multiple times within a module without repeating it.

  ```
  locals {
    common_tags = {
      owner = "DevOps Team"
      service = "backend"
    }
  }

  resource "aws_instance" "app-dev" {
      ami             = "ami-00f7e5c52c0f43726"
      instance_type   = "t2.micro"
      tags            = local.common_tags
  }

  resource "aws_instance" "db-dev" {
      ami             = "ami-00f7e5c52c0f43726"
      instance_type   = "t2.small"
      tags            = local.common_tags
  }

  resource "aws_ebs_volume" "db-ebs" {
      availability_zone   = "us-west-2a"
      size                = 8
      tags                = local.common_tags
  }

  ```

- Local values can be used for multiple different use-cases like having a conditional expression

  ```
  locals {
    name_prefix = "${var.name != "" ? var.name : var.default}"
  }
  ```

Important Points for __local values__
- Local values can be helpful to avoid repeating the same values or expressions multiple times in a configuration
- If overused they can also make a configuration hard to read by future maintainers by hiding the actual values used
- __use local values only in moderation__, in situtations where a single value or result is used in many places and that value is likely to be changd in future 

---

## Terrafrom functions

Terraform Language includes a number of built-in functions that you can use to transform and combine values.

The general syntax for function calls is a function name followed by comma-separated arguments in parentheses:

```
function(argument1, argument2)
```

Example :

```
max(5, 12, 9) 
```

__Terraform language does not support user-defined functions__, and so only the functions built in to the langugage are available for use.

High level categories of Terraform functions
- Number
- String
- Collection
- Encoding
- Filesystem
- Date and Time
- Hash and Crypto
- IP Network
- Type Conversion

Terraform Docs:
<https://www.terraform.io/docs/language/functions/index.html>
- Documentation has useful examples for functions in terraform

We can experiment with the behavior of Terraform's built-in functions from the Terraform expression console, by running the `terraform console` command, which provides an interactive console for evaluating expressions.:

```bash
terraform console
> max(5, 12, 9)
12
> 
```

Functions are very useful.

---

## Data Sources in Terraform

Data sources allow data to be fetched or computed for use elsewhere in Terraform configuration.

Example -

```
data "aws_ami" "app_ami" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

resource "aws_instance" "instance-1" {
  ami = data.aws_ami.app_ami.id
  instance_type = "t2.micro"
}
```

- datasource is defined using `data` block
- Reads from a specific datasource, for above example datasource is `aws_emi` and exports results under `app_emi`

### Filters in Data Sources

- If you need to find more details related to options that can be used in filters, you can refer to the following AWS documentation:
<https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-instances.html>

- Refer to the --filters option

>Note: This additional details is beyond the scope of certification.

---

## Debugging in Terraform

- Terraform has detailed logs which can be enabled by setting the `TF_LOG` environment variable to one of the log levels 
  - `TRACE`, 
  - `DEBUG`, 
  - `INFO`, 
  - `WARN`, 
  - `ERROR` 
  
  and terraform command will now output the detialed logs in the console.

  ```bash
  export TF_LOG=TRACE
  ```

- `TRACE` is the most verbose and it is the default if `TF_LOG` is set to something other than a log level name.
- To persist logged output we can set `TF_LOG_PATH` in order to force the log to always be appended to a specific file when logging is enabled
  ```
  export $TF_LOG_PATH=/tmp/terrafrom-trace.log
  ```

---

## Terraform Format 

`terraform fmt` command is used to rewrite Terraform configuration files to take care of overall formatting which is important for code readability.
```
terraform fmt
```

---

## Terraform Validate 

`terraform validate` primarily checks whether a configuration is syntactically valid.

It can check various aspects including unsupported arguments, undeclared variables and others.

```bash
terraform validate
```

when we run `terraform plan` validation happens behined the scenes.

---

## Load Order & Semantics
- Terraform generally loads all the configuration files within the directory specified in alphabatical order.
- The files loaded must end in either `.tf` or `.tf.json` to specify the format that in use.
- It is recommended to split the terraform code across multiple configuration files -
  - `provider.tf`
     ```
      terraform {
        required_providers {
          aws = {
            source = "hashicorp/aws"
            version = "4.34.0"
          }
        }
      }

      provider "aws" {
        # Configuration options
        region = "us-west-2"
      }
     ```
  - `variables.tf`
    ```
    variable "iam_user" {
      default = "demouser"
    }
    ```
  - `ec2.tf`
    ```
    resource "aws_instance" "myec2" {
      ami = "ami-082b5a644766e0e6f"
      instance_type = "t2.micro"
    }
    ```
  - `iam.user.tf`
    ```
    resource "aws_iam_user" "lb" {
      name = var.iam_user
      path = "/system/"
    }
    ```

---

## Dynamic Blocks

The challenge
- In many use-cases, there are repeatable nested blocks that needs to be defined. This can lead to a long code and it can be difficult to manage in a longer time.
- `dynamic` block allows us to dynamically construct repeatable nested blocks which is supported inside `resource`, `data`, `provider`, and `provisioner` blocks.

Example: Dynamic Block

```
# List of multiple port values
variable "sg_ports" {
  type        = list(number)
  description = "list of ingress ports"
  default     = [8200, 8201, 8300, 9200, 9500]
}

# dynamic block for multiple ingress ports
resource "aws_security_group" "dynamicsg" {
  name        = "dynamic-sg"
  description = "Ingress for Vault"

  dynamic "ingress" {
    for_each = var.sg_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}
```

### Iterators
- the `iterator` argument (optional) sets the name of a temporary variable that represents the current element of the complex value.
- If omitted, the name of the variable defaults to the label of the dynamic block (`ingress` in the example)

  ```
  variable "sg_ports" {
    type        = list(number)
    description = "list of ingress ports"
    default     = [8200, 8201, 8300, 9200, 9500]
  }

  resource "aws_security_group" "dynamicsg" {
    name        = "dynamic-sg"
    description = "Ingress for Vault"

    # dynamic block ingress with iterator
    dynamic "ingress" {
      for_each = var.sg_ports
      iterator = port           # iterator 

      content {
        from_port   = port.value
        to_port     = port.value
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }
    }
    
    # dynamic block egress without iterator
    dynamic "egress" {
      for_each = var.sg_ports

      content {
        from_port   = egress.value
        to_port     = egress.value
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }
    }
  }
  ```

---

## Tainting Resources

The `terraform taint` command manually marks a Terraform-managed resource as tainted forcing it to be destroyed and recreated on the next apply.

```
terraform taint resourcetype.resourcename
```

Example -

```
resource "aws_instance" "myec2" {
  ami = "ami-082b5a644766e0e6f"
  instance_type = "t2.micro"
}
```
```
terraform taint aws_instance.myec2
Resource instance aws_instance.myec2 has been marked as tainted.
```

Important points
- `terraform` taint command will not modify infrastructure, but does modify the state file in order to mark a resource as tained (`"status": "tainted"`).
- Once a resource is marked as tainted, the next plan will show the resource will be destroyed and recreated and the next apply will implement this change.
- Note that tainting a resource for recreation may affect resources that depend on the newly tainted resource. For example if we destroy and recreate an ec2 instance its ip may change and if a dns points to the older ip it needs to be updated with the newer ip of recreated ec2 instance.

---

## Splat Expressions `[*]`

Splat Expression allows us to get a list of all the attributes

```
resource "aws_iam_user" "lb" {
  name    = "iamuser.${count.index}"
  count   = 3
  path    = "/system/"
}

output "arns" {
  value = aws_iam_user.lb[*].arn  # Splat Expresssion [*]
}
```

---
 
## Terraform Graph

The `terraform graph` command is used to generate a visual representation of either a configuration or execution plan 

The output of `terraform graph` command is in the DOT format, which can easily be converted to an image.

```
terraform graph
```

Store `terraform graph` output in a file 
```
terraform graph > graph.dot
```

We can visualize the DOT contents, We can use graphviz <https://graphviz.gitlab.io/download/>

Convert a dot file to an svg file
```
cat graph.dot | dot -Tsvg > graph.svg
```

---

## Saving Terraform plan to a file

Terraform plan can be saved to a specific file. This plan can then be used with terraform apply to be certain that only the changes shown in this plan are applied.

Syntax
```
terrafor plan -out=<path>
```

Example 
```
terraform plan -out=demopath
```

Above terraform plan command creates a binary file `demopath` and we can perform exact same actions by using terraform apply command 
```
terraform apply "dempath"
```

---

## Terraform Output

`terraform output` command can be used to extract the value of an output variable from the state file 

Synatx
```
terraform output <outputvariable>
```

---

## Terraform Settings

The special `terraform` configuration block is used to configure some behaviours of Terraform itself, such as requiring a minimum Terraform version to apply your configuration.

Terraform settings are gathered togeather into terraform blocks:

```
terraform {
  # ...
}
```

Example
```
terraform {
  required_version = "1.2.9"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.34.0"
    }
  }
}
```

__Terraform Version__

the `required_version` setting accepts a version constraint string, which specifies which versions of Terraform can be used with your configuration.

If the running version of Terraform doesn't match the constraints specified, Terraform will produce an error and exit without taking any further actions

```
terraform {
  required_version = "> 0.12.0"
}
```

__Provider Version__

the `required_providers` block specifies all of the providers required by the current module, mapping each local provider name to a source address and a version constraint.

```
terraform {
  required_providers {
    mycloud = {
      source = "mycorp/mycloud"
      version = "~> 1.0"
    }
  }
}
```

---

## Dealing with Large Infrastructure

When you have a larger infrastructure, you will face issue related to API limits for a provider

- Switch to smaller configuration where each can be applied independently

  - The `-target=resource` flag can be used to target specific resource. This is generally used as a means to operate on isolated portions of very large configurations.

    ```
    terraform plan -target=ec2
    ```
  - `-target` option is not for routine use and is only provided for exceptional situations
- We can prevent terraform from querying the current state during operations like terraform plan by specifying `-refresh=false` flag.

  ```
  terraform plan -refresh=false
  ```

> It is not recommended to use `-refresh` and `-target` flags extensively and are only used in special scenarios

---

## zipmap Function

The `zipmap` function constructs a `map` from a list of keys and a corresponding list of values.

Syntax
```
zipmap(keyslist, valuelist)
```

Example
```console
> zipmap (["pineapples","oranges","strawberry"], ["yellow","orange","red"])
{
  "oranges" = "orange"
  "pineapples" = "yellow"
  "strawberry" = "red"
}
```

`zipmap` Terraform usecase example :

```
resource "aws_iam_user" "lb" {
  name = "iamuser.${count.index}"
  count = 3
  path = "/system/"
}

output "arns" {
  value = aws_iam_user.lb[*].arn
}

output "names" {
  value = aws_iam_user.lb[*].name
}

output "combined" {
  value = zipmap(aws_iam_user.lb[*].name, aws_iam_user.lb[*].arn)
}
```

---
## Comments in Terraform Code

A comment is a text note added to source code to provide explanatory information, usually about the function of the code


Terraform language support three different syntaxes for comments:

| Type | Description |
|-|-|
| `#` | Begins a single line comment, ending at the end of the line |
| `//` | also begins a single-line comment, as an alternative to `#` |
| `/*` and `*/` | are start and end delimiters for a comment that might span over multiple lines |


```hcl
# This is a single line comment with #
// This is another single line comment with //

/* 
This is a multiline comment
I can write paragraphs here
I can also comment a terraform code
*/

resource "aws_iam_user" "lb" {
  name = "iamuser.${count.index}"
  count = 3
  path = "/system/"
}
```

---
## Challenges with Count Meta-Argument

- resource are identified by the index value from the list and index value starts form `0`
  ```
  variable "iam-names" {
    type = list
    default = ["user-01","user-02", "user-03"]
  }

  resource "aws_iam_user" "iam" {
    name = var.iam_names[count.index]
    count = 3
    path = "/system"
  }

  ```

| Resource Address | Infrastructure |
|-|-|
| aws_iam_user.iam[0] | user-01 |
| aws_iam_user.iam[1] | user-02 |
| aws_iam_user.iam[2] | user-03 |


Challenges 
-  If the order of elements of index is changed, this can impact all of the other resources. For example adding a new value at the start of variable list will change the address of other existing values in the list. This can messup existing infra

    ```
    variable "iam-names" {
      type = list
      default = ["user-new" "user-01","user-02", "user-03"]
    }
    ```

Important Note
- If your resources are almost identical, `count` is appropriate.
- If distinctive values are needed in the arguments, usage of `for_each` is recommended.


---

## Data Type - SET

### Basics of List
- List are used to store multiple items in a single variable
- List items are ordered, changeable, and allow duplicate values
- List items are indexed, the first item has index[0], the second item has index[1] ...

```
variable "iam_names" {
  type = list
  default = ["user-01","user-02","user-03"]
}
```

### Understanding SET
- SET is used to store multiple items in a single variable
- SET items are unordered and no duplicate allowed

```
exampleset = {"apple", "banana", "mango"}
```

### `toset` Function 

- `toset` function will convert the list of values to SET
- when converting a list with duplicate values the ordering of the elements is lost and any duplicate values are coalesced

```
> toset(["a","b","c","a"])
toset([
  "a",
  "b",
  "c",
])

```


---
## for_each in Terraform

- `for_each` makes use of map/set as an index value of the created resource

```
resource "aws-iam-user" "iam" {
  for_each = toset(["user-01","user-02","user-03"])
  name     = each.key
}
```



### Replication Count Challenge
- If a new element is added, it will not affect the other resources

```
resource "aws-iam-user" "iam" {
  for_each = toset(["user-0", "user-01","user-02","user-03"])
  name     = each.key
}
```

| Resource Address | Infrastructure |
|-|-|
| aws_iam_user.iam[user-0] | user-0 |
| aws_iam_user.iam[user-01] | user-01 |
| aws_iam_user.iam[user-02] | user-02 |
| aws_iam_user.iam[user-03] | user-03 |

### The `each` object
In blocks where `for_each` is set, an additional `each` object is available

This object has two attributes:

| `each` object | Description |
|-|-|
| `each.key` | The map key (or set member) corresponding to the instance | 
| `each.value` | The map value corresponding to this instance | 

Example
```
resource "aws_instance" "myec2" {
  ami = "ami-0cea098ed2ac54925"
  for_each = {
    key1 = "t2.micro"
    key2 = "t2.medium"
  }
  instance_type = each.value
  key_name      = each.key      # The index `aws_instance.myec2["key1"]`
  tags = {
    Name = each.value
  }
}
```

---