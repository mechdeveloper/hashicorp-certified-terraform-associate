# Getting Started & Setting Up Labs

## Configuration Management vs Infrastructure Orchestration 

- Ansible, Chef, Puppet are configuration management tools which means that they are primarily designed to install and manage software on existing servers.
- Terraform, CloudFormation are the infrastructure orchestration tools which basically means they can provision the servers and infrastructure by themselves.
- Configuration Management toools can do some degree of infrastructure provisioning, but the focus here is that some tools are going to be better fit for certain type of tasks.

## Which tool to choose?

- Is your infrastructure vendor specific in longer term? Example AWS.
- Are you planning to have multi-cloud / hybrid cloud based infrastructure?
- How well does it integrate with configuration management tools?
- Price and Support


## Terraform 
- Supports multiple platforms, has hundreds of providers.
- Simple configuration language and faster learning curve.
- Easy integration with configuration management tools like Ansible.
- Easily extensible with the help of plugins
- Free !

## Installing Terraform

- download terraform binary 
- set environment path variable

---
