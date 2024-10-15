packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "region" {
  default = "us-west-2"
  type    = string
}

variable "github_repo" {
  default = ""
  type    = string
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "aws-ubuntu-runner"
  instance_type = "t2.micro"
  region        = var.region
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-noble-24.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  tags = {
    type  = "runner"
    build = "ubuntu-buildah"
  }
  ssh_username = "ubuntu"
}


build {
  name    = "ec2-runner"
  sources = ["source.amazon-ebs.ubuntu"]

  provisioner "shell" {
    inline = [
      "sudo apt-get -y update",
      "sudo snap install aws-cli --classic",
      "sudo snap install amazon-ssm-agent --classic",
      "sudo apt-get -y install buildah"
    ]
  }

  provisioner "file" {
    sources     = ["./runner.py", "./runner.service", "./shutdown-runner.service"]
    destination = "/tmp/"
  }

  provisioner "shell" {
    inline = [
      "echo GITHUB_REPO=${var.github_repo} | sudo tee -a /etc/environment",
      "echo 'unqualified-search-registries=[\"docker.io\"]' | sudo tee -a /etc/containers/registries.conf"
    ]
  }

  provisioner "shell" {
    script = "./bootstrap.sh"
  }
}
