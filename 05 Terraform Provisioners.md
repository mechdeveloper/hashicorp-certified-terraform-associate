# Terraform Provisioners

Provisioners can be used to model specific actions on the local machine or on a remote machine in order to prepare servers or other infrastructure objects for service.

Provisioners can excute scipts on a local or remote machine as part of resource creation or destruction. for example, on creating an ec2 instance execute a script which installs Nginx web-server.

## Creation-Time Provisioners

By default, provisioners run when the resource they are defined within is created. Creation-time provisioners are only run during creation, not during updating or any other lifecycle. They are meant as a means to perform bootstrapping of a system.

If a creation-time provisioner fails, the resource is marked as __tainted__. A tainted resource will be planned for destruction and recreation upon the next `terraform apply`. 

Terraform does this because a failed provisioner can leave a resource in a semi-configured state. Because Terraform cannot reason about what the provisioner does, the only way to ensure proper creation of a resource is to recreate it. This is tainting.You can change this behavior by setting the `on_failure` attribute.

## The `self` Object
Expressions in provisioner blocks cannot refer to their parent resource by name. Instead, they can use the special `self` object.

The `self` object represents the provisioner's parent resource, and has all of that resource's attributes. For example, use `self.public_ip` to reference an `aws_instance`'s `public_ip` attribute.

>Technical note: Resource references are restricted here because references create dependencies. Referring to a resource by name within its own block would create a dependency cycle.


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

## Failure Behavior

By default, provisioners that fail will also cause the Terraform apply itself to fail. The `on_failure` setting can be used to change this. The allowed values are:

- `continue` - Ignore the error and continue with creation or destruction.
- `fail` - Raise an error and stop applying (the default behavior). If this is a creation provisioner, taint the resource.

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

## Generic Provisioners

### `file`

The `file` provisioner is used to copy files or directories from the machine executing Terraform to the newly created resource. The `file` provisioner supports both `ssh` and `winrm` type connections.

>Note: Provisioners should only be used as a last resort. For most common situations there are better alternatives.

Example

```
resource "aws_instance" "web" {
  # ...

  # Copies the myapp.conf file to /etc/myapp.conf
  provisioner "file" {
    source      = "conf/myapp.conf"
    destination = "/etc/myapp.conf"
  }

  # Copies the string in content into /tmp/file.log
  provisioner "file" {
    content     = "ami used: ${self.ami}"
    destination = "/tmp/file.log"
  }

  # Copies the configs.d folder to /etc/configs.d
  provisioner "file" {
    source      = "conf/configs.d"
    destination = "/etc"
  }

  # Copies all files and folders in apps/app1 to D:/IIS/webapp1
  provisioner "file" {
    source      = "apps/app1/"
    destination = "D:/IIS/webapp1"
  }
}
```


### `local-exec` Provisioner

The `local-exec` provisioner invokes a local executable after a resource is created. This invokes a process on the machine running Terraform, not on the resource. 

one most useful approach of local-exec is to run ansible-playbooks on the created server after the resource is created.

```
resource "aws_instance" "web" {
  # ...

  provisioner "local-exec" {
    command = "echo ${self.private_ip} >> private_ips.txt"
  }
}
```

### `remote-exec` Provisioner

The `remote-exec` provisioner invokes a script on a remote resource after it is created. This can be used to run a configuration management tool, bootstrap into a cluster, etc.

The `remote-exec` provisioner requires a connection and supports both `ssh` and `winrm`.

Example 

```
resource "aws_instance" "web" {
  # ...

  # Establishes connection to be used by all 
  # generic remote provisioners (i.e. file/remote-exec)
  connection {
    type     = "ssh"
    user     = "root"
    password = var.root_password
    host     = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "puppet apply",
      "consul join ${aws_instance.web.private_ip}",
    ]
  }
}
```

Example

- Create a keypair in AWS

```
resource "aws_instance" "myec2" {

    ami = "ami-00f7e5c52c0f43726"
    instance_type = "t2.micro"
    keyname = "keypair"

    # Establishes connection to be used by all 
    # generic remote provisioners (i.e. file/remote-exec)
    connection {
        type        = "ssh"
        user        = "ec2_user"
        privatekey  = file(./keypair.pem)
        host        = self.public_ip
    }

    provisioner "remote-exec" {
        inline = [
            "sudo amazon-linux-extras install -y nginx1.12",
            "sudo systemctl start nginx",
        ]
    }
}
```

## Vendor Provisioners

### `chef` Provisioner
### `habitat` Provisioner
### `puppet` Provisioner
### `salt-masterless` Provisioner
