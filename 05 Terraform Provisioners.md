# Terraform Provisioners

- Provisioners can be used to model specific actions on the local machine or on a remote machine in order to prepare servers or other infrastructure objects for service.

- Provisioners can excute scipts on a local or remote machine as part of resource creation or destruction. for example, on creating an ec2 instance execute a script which installs Nginx web-server.

  Example: On creation of a web server execute scripts to install Nginx

---

# Types of Provisioners

Terraform has capability to turn provisioners both at the time of creation as well as destruction

There are two main types of provisioners
- `local-exec`
- `remote-exec`

## `local-exec` Provisioner

- The `local-exec` provisioner invokes a local executable after a resource is created. 
- This invokes a process on the machine running Terraform, not on the resource. 

- one useful usecase of `local-exec` is to execute __ansible-playbooks__ once the resource is created.

```
resource "aws_instance" "web" {
  # ...

  provisioner "local-exec" {
    command = "echo ${self.private_ip} >> private_ips.txt"
  }
}
```

## `remote-exec` Provisioner

- The `remote-exec` provisioner allows to invoke a script directly on a remote server. 
- This can be used to run a configuration management tool, bootstrap into a cluster, etc.
- The `remote-exec` provisioner requires a connection and supports both `ssh` and `winrm`.



## Other Provisioners types

### `chef` Provisioner
### `habitat` Provisioner
### `puppet` Provisioner
### `salt-masterless` Provisioner

---

# Implementing `remote-exec` provisioners

Documentation: 
<https://developer.hashicorp.com/terraform/language/resources/provisioners/remote-exec?optInFrom=terraform-io>

- The `remote-exec` provisioner invokes a script on a remote resource after it is created. 
- Create a keypair in AWS  (`private-key`), this is required to ssh into the server


```
resource "aws_instance" "myec2" {

    ami = "ami-00f7e5c52c0f43726"
    instance_type = "t2.micro"
    key_name = "private-key"

    # Establishes connection to be used by all 
    # generic remote provisioners (i.e. file/remote-exec)
    connection {
        type        = "ssh"
        user        = "ec2_user"
        private_key = file("./private-key.pem") 
        host        = self.public_ip
    }

    provisioner "remote-exec" {
        inline = [
            "sudo amazon-linux-extras install -y nginx1",
            "sudo systemctl start nginx",
        ]
    }
}
```

---
# Implementing `local-exec` provisioners
- `local-exec` provisioner allows us to invoke a local executable after the resource is created
- One of the most used apporach of local-exec provisioner is to run ansible-playbooks on the created server after the resource is created.

```
resource "aws_instance" "myec2" {
  ami = "ami-00f7e5c52c0f43726"
  instance_type = "t2.micro"

  provisioner "local-exec" {
    command = "echo ${aws_instance.myec2.private_ip} >> private_ips.txt"
  }
}
```


---
# Creation-Time & Destroy-Time Provisioners

There are two primary types of provisioners

| Type | Description |
|-|-|
| Creation-Time | Creation-time provisioners are only run during creation, not during updating or any other lifecycle. If a creation-time provisioner fails, the resource is marked as tainted. |
| Destroy-Time | Destroy-time provisioners are run before the resource is destroyed |

## Destroy-Time Provisioners

If `when = destroy` is specified, the provisioner will run when the resource it is defined within is destroyed.

```
resource "aws_instance" "web" {
  # ...

  provisioner "local-exec" {
    when    = destroy
    command = "echo 'Destroy-time provisioner'"
  }
}
```

Destroy provisioners are run before the resource is destroyed. If they fail, Terraform will error and rerun the provisioners again on the next terraform apply. Due to this behavior, care should be taken for destroy provisioners to be safe to run multiple times.

>NOTE: A destroy-time provisioner within a resource that is tainted will not run. This includes resources that are marked tainted from a failed creation-time provisioner or tainted manually using terraform taint.

## Creation-Time Provisioners

- By default, provisioners run when the resource they are defined within is created. Creation-time provisioners are only run during creation, not during updating or any other lifecycle. They are meant as a means to perform bootstrapping of a system.

- If a creation-time provisioner fails, the resource is marked as __tainted__. A tainted resource will be planned for destruction and recreation upon the next `terraform apply`. 

- Terraform does this because a failed provisioner can leave a resource in a semi-configured state. Because Terraform cannot reason about what the provisioner does, the only way to ensure proper creation of a resource is to recreate it. This is tainting. You can change this behavior by setting the `on_failure` attribute.

## The `self` Object
Expressions in provisioner blocks cannot refer to their parent resource by name. Instead, they can use the special `self` object.

The `self` object represents the provisioner's parent resource, and has all of that resource's attributes. For example, use `self.public_ip` to reference an `aws_instance`'s `public_ip` attribute.

>Technical note: Resource references are restricted here because references create dependencies. Referring to a resource by name within its own block would create a dependency cycle.

---
# Failure Behaviour for Provisioners

## Failure Behavior

By default, provisioners that fail will also cause the Terraform apply itself to fail. The `on_failure` setting can be used to change this. 

The allowed values are:
| | |
|-|-|
| `continue` | Ignore the error and continue with creation or destruction. |
| `fail` | Raise an error and stop applying (the default behavior). If this is a creation provisioner, taint the resource. |

Example
```
resource "aws_instance" "web" {
  # ...

  provisioner "local-exec" {
    command    = "echo The server's IP address is ${self.private_ip}"
    on_failure = continue
  }
}
```
---
# `null_resource`

The `null_resource` implements the standard resource lifecycle but takes no futher action

Example

```
resource "aws_eip" "lb" {
  vpc = true
  depends_on = [null_resource.health_check] 
}

# null resource
resource "null_resource" "health_check" {

  provisioner "local-exec" {
    command = "curl https://google.com"
    # useful in checking the dependencies before creating resources
  }
}

```

The `triggers` argument allows specifying an arbitrary set of values that, when changed, will cause the resource to be replaced.
- `triggers` (Map of String) A map of arbitrary strings that, when changed, will force the null resource to be replaced, re-running any associated provisioners.

Example
```
resource "aws_eip" "lb" {
  vpc   = true
  count = 1               
  # changing count will activate trigger and provisioner will rerun
}

resource "null_resource" "ip_check" {

  triggers = {
    latest_ips = join(",", aws_eip.lb[*].public_ip)
  }

  provisioner "local-exec" {
    command = "echo Latest IPs are ${null_resource.ip_check.triggers.latest_ips}" > sample.txt"
  }
}

```
---