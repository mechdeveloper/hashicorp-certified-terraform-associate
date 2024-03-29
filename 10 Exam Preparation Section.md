# Exam Preparation

## Important Pointers Part 01

- Terraform Providers
- terraform init
- terraform plan
- terraform apply
- terraform refresh
- terraform destroy
- terraform fmt
- terraform validate
- Terraform Provisioners
  - local-exec
  - remote-exec

## Important Pointers Part 02

- Terraform Debugging
  - TF_LOG 
  - TF_LOG_PATH
- terraform import
- Local Values
- Data Types
  - string
  - list
  - map
  - number
- Terraform WorkSpaces
  - Multiple state files
- Terraform Modules
  - Root
  - Child
  - Accessing Output Values
- Supressing values in CLI output
  - sensitive argument
- Module Versions
  - while fetching a module having a version is required 
  - It is not mandatory to include the module version argument when pulling the code from terraform registry
- Terraform Registry
  - `<NAMESPACE>/<NAME>/<PROVIDER>`
- Private Registry Module Sources 
  - `<HOSTNAME>/<NAMESPACE>/<NAME>/<PROVIDER>`
  

## Important Pointers Part 03

- Terraform Functions
- Count & Count Index
- Terraform state Lock
  - `force-unlock`
- Resource Block
- Sentinel (policy-as-code)
- Sensitive Data in State File
- Dealing with Credentials in Config
- Remote Backend for Terraform Cloud
  - full remote operations


## Important Pointers Part 04

- terraform graph
- Splat Expression `resource-type.local-name[*].attribute`
- Terraform Terminologies
- Provider Configuration
- terraform output
- Terraform Lock
  - terraform force-unlock

## Important Pointers Part 05

- Terraform Enterprise & Terraform Cloud
- variables with undefined values
- Environment Variables TF_VAR_name
- Structural Data Types
  - List (same type)
  - Object (own type)
    ```
    {
      <ATT_NAME> = <TYPE>, 
      ...
    }
    {
      name = string
      age = number
    }
    {
      name = "john"
      age = 52
    }
    ```
  - tuple 
    ```
    [<TYPE>, ...]
    ```
- backend configuration
  - First time configuration (option to migrate)
  - Partial time configuration 
- terraform taint
- provisioner
  - local-exec
  - remote-exec
    - ssh
    - winrm
- provisioner failure behaviour
  - on_failure
    - continue
    - fail # Default
- provisioner types
  - Creation-Time Provisioner
  - Destroy-Time Provisioner
- input variables 
  - cli
  - terraform.tfvars
  - custom.tfvars with (-var-file)

- Variable Definition Precedence (later sources taking precedence)
  - Environment Variables
  - terraform.tfvars
  - terraform.tfvars.json
  - *.auto.tfvars or *.auto.tfvars.json files processed in lexical order of their file names
  - any -var and -var-file options in command line in the order they are provided
  - if same variable is provided multiple times terraform will use the last value it finds

- local backend (default)
- required_providers (matches provider version)
- required_version (matches terraform version)
  - versioning arguments
    - `>=`
    - `<=`
    - `~>`
    - `>=, <=`

## Important Pointers Part 06

- fetching values from a map 
  - `var.ami_ids["mumbai"]`

- Terraform and GIT (.gitignore file)
- modules using special `git::` prefix
  - `ref` argument to fetch different branch / tag names

- terraform workspace
  - not suitable for strong isolation (stage/prod)
  - create and switch automatically (terrraform workspace new prod)
  - switch (terraform workspace select default)
  

- dependency types
  - implicit (automatic object references)
  - explicit (depends_on argument)

- terraform state command
  - list
  - mv
  - pull
  - rm 
  - show

- datasource code

- `terraform taint [options] address`
  - terraform taint "module.couchbase.aws_instance.cb_node[9]"
  - terraform taint "module.foo.module.bar.aws_instance.qux"

- preview terraform destroy behaviour
  `terraform plan -destroy`

- terraform module sources
  - local paths
  - Terraform Registry
  - GitHub
  - S3 buckets
  - others
- dealing with larger infrastructure 
  - rate limiting
  - break larger config in to smaller configurations
  - workaround (not recommended)
    - `refresh=false`
    - `-target` flag
- lookup(map, key, default) - to retrieve single element from a map
- implicit terraform refresh
  - plan, apply, refresh
  - not implicit referesh on init and import
- array datatype is not supported in terraform
- Various variable definition files will be loaded automatically in terraform
  - terraform.tfvars
  - terraform.tfvars.json
  - Any files with names ending with .auto.tfvars.json
- both implicit and explicit dependency information is stored in `terraform.tfstate` file
- `terraform init -upgrade` command upgrades all the plugins to newest version
- evaluate expressions using `terraform console`
- defining variables difference b/w 0.11 and 0.12
  - "${var.instance_type}" - 0.11
  - var.instance_type - 0.12

## Updated - Important Pointers for Exams
Important Note:
1. Requirements for publishing module in Terraform Registry

    Ensure that you know the list of requirements for publishing modules in the Terraform registry.

    <https://www.terraform.io/docs/registry/modules/publish.html>

2. List:

    list(...): a sequence of values identified by consecutive whole numbers starting with zero. The keyword list is a shorthand for list(any), which accepts any element type as long as every element is the same type

    We cannot use all words within variable names. Terraform reserves some additional names that can no longer be used as input variable names for modules. These reserved names are:
    ```
    count
    depends_on
    for_each
    lifecycle
    providers
    source
    ```

3. Air Gapped

    If terraform needs to be installed in an environment without internet access, the installation is referred to as air-gapped

    <https://www.terraform.io/docs/enterprise/install/installer.html>

4. Index Function
    index finds the element index for a given value in a list.

    <https://www.terraform.io/docs/configuration/functions/index.html>

5. Terraform Enterprise

    Before mid-2019, all distributions of Terraform Cloud used to be called Terraform Enterprise; the self-hosted distribution was called Private Terraform Enterprise (PTFE).

    Terraform Enterprise supports the following data storage:

    PostgresSQL

    Any S3-compatible object storage service, GCP Cloud Storage or Azure blob storage meets Terraform Enterprise's object storage requirements.

    If you already run your own Vault cluster in production, you can configure Terraform Enterprise to use that instead of running its own internal Vault instance.

    <https://www.terraform.io/docs/enterprise/before-installing/index.html>

6. VCS Provider Support for Terraform Provider

    ```
    GitHub.com

    GitHub.com (OAuth)

    GitHub Enterprise

    GitLab.com

    GitLab EE and CE

    Bitbucket Cloud

    Bitbucket Server

    Azure DevOps Server

    Azure DevOps Services
    ```

    <https://www.terraform.io/docs/cloud/vcs/index.html>

7. Zipmap function

    <https://www.terraform.io/docs/configuration/functions/zipmap.html>

8 Supported Format for Comments

    The Terraform language supports three different syntaxes for comments:
    ```
    #
    //
    /* and */
    ```
    <https://www.terraform.io/docs/configuration/syntax.html>

# Miscellaneous Pointer

- GitHub is not the supported backend type in Terraform.
<https://www.terraform.io/docs/backends/types/index.html>

- When running `terraform init`, the plugins are downloaded in the sub-directory of the present working directory at the path of `.terraform/plugins`

- API and CLI access for Terraform Cloud can be managed through API tokens that can be generated from Terraform Cloud UI.

- Terraform uses Parallelism to reduce the time it takes to create the resource. By default, this value is set to 10

- Terraform recommends using an Indent two spaces for each nesting level.
  ```
  ami           = "abc123"
  instance_type = "t2.micro"
  ```

- Following are the two CLI configuration file for Terraform:

  ```
  .terraformrc
  terraform.rc
  ```
  <https://www.terraform.io/docs/commands/cli-config.html>

- The `terraform get` command is used to download and update modules mentioned in the root module.

- The Sentinel command-line interface (CLI) allows for the developing and testing of policies outside of a particular Sentinel implementation

- The flag to save plan to a file:  `-out=FILENAME`
- Name of the Default State file: `terraform.tfstate`
---