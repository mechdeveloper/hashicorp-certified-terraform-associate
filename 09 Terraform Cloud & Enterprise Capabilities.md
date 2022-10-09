# Terraform cloud 

Terraform cloud manages Terraform runs in a consistent and reliable environment with various features like access controls, private registry for sharing modules, policy controls and others.

- Workspaces
  - collaborate on terraform runs
  - cost estimation
  - approvals for terraform apply
- Modules
  - Private registry for sharing a module 
- Settings
  - VCS Providers 
    - Configure git repository for terraform project
  - Cost Estimation
    - Displays estimated monthly cost for resources provisioned
  - Sentinel Policies
    - Create policies and enfore them 


## Create Terraform Cloud Account
- Setup workflow
  - Create organization
    - Create a new Workspace
      - Choose workflow
        - Version Control workflow
        - CLI-driven workflow
        - API-driven workflow

## Terraform Cloud Offerings 

| Free | Team & Governance | Business |
|-|-|-|
| Free | Starting at $20 / user | Contact Sales |
| - Open Source Features, plus: <br> - State Management <br> - Remote operations <br> - Private module registry <br> - Community support   | Everything in FREE, with options to add: <br> - Team management <br> - Sentinel Policy as code <br> - Run tasks <br> - Policy enforcement <br> - Bronze support  | Everything in Team & Governance, Plus: <br> - SSO, self-hosted agents, audit logs <br> - Custom concurrency <br> - Sel-hosted option <br> - Bronze, Silver, or Gold support  |


---

# Sentinel

Sentinel is a policy as a code framework integrated with the HashiCorp Enterprise products.

It enables fine-grained, logic-based policy decisions, and can be extended to use information from external sources.

>Note: Sentinel policies are paid feature

```terraform plan --> sentinel checks --> terraform apply```

High level structure

- Workspace
  - Policy Sets
    - Policy 
      - `Block EC2 without tags`
      - Enforcement mode
        - hard-mandatory (cannot override)
        - soft-mandatory (can override)
        - advisory (logging only)


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

---
# Remote Backends

## Terraform Cloud - Backend Operation Types

- The remote backend stores terraform state and may be used to run operations in Terraform Cloud.
  - Backend Operations
    - Local
      - in this case only state is stored in the Terraform Cloud backend
    - Remote
      - State is stored in Terraform Cloud backend
      - full remote operations like plan, apply are executed on Terrafom Cloud Backend

## Remote Operations 

When using full remote operations, operations like terraform plan or terraform apply can be executed in Terraform Cloud's run environment, with output streaming to the local terminal.

## Implementing Remote Backend Operations in Terraform Cloud

Documentation

<https://www.terraform.io/docs/backends/types/remote.html>


- Create CLI Driven workflow
- Configure terraform
  `remote-backend.tf`
  ```
  terraform {
    cloud {
      organization = "ashishbaghel-org"
      workspaces {
        name = "remote-operation"
      }
    }
  }
  ```

- Login to terraform cloud
  ```
  terraform login
  ```
  terraform will store the token in local machine in plain text

- Initialize terraform cloud
  ```
  terraform init
  ```
- Run terraform plan
  ```
  terraform plan
  ```

- Run terraform apply
  ```
  terraform plan
  ```

- Destroy resources
  ```
  terraform destroy
  ```

---

# Air Gapped Environments

- An air gap is a network security measure employed to ensure that a secure computer network is physically isolated from unsecured networks, such as public internet
- Air Gapped environments are used in various areas 
  - Military/Government computer networks/systems
  - Financial computer systems, such as stock exchanges
  - Industrial control systems, such as SCADA in Oil & Gas fields
- Terraform Enterprise installs using either an online or air gapped method and as the names infer, one requires internet connectivity, the other does not.