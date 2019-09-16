# variables
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "private_key_path" {
    default = "$HOME/.ssh/"
}
variable "key_name" {
    default = "hfy-macpro"
}
variable "network_address_space" {
    default = "10.1.0.0/16"
}
variable "subnet1_address_space" {
    default = "10.1.1.0/24"
}
variable "subnet2_address_space" {
    default = "10.1.2.0/24"
}

variable "vpc_cidr_block" {
    default = "10.1.0.0/16"
}

variable "aws_vpc_id" {
    default = "sdwan_lab"
}
# variable "aws_vpc.vpc.id"

# provider
provider "aws" {
    # access_key = "${var.aws_access_key}"
    # secret_key = "${var.aws_secret_key}"
    shared_credentials_file = "~/.aws/credentials"
    region = "us-east-1"
}

# resource
resource "aws_vpc" "sdwan_lab" {
    cidr_block = "${var.vpc_cidr_block}"

    tags = {
        Name = "SDWAN_LAB"
    }
}
resource "aws_instance" "vEdge" {
    ami           = "ami-0dc32351148728c30"
    instance_type = "t2.medium"
    key_name = "${var.key_name}" # key that you're going to use to ssh into the instance using that keypair
    vpc_id = "${aws_vpc.sdwan_lab}"

  connection {
    user        = "admin"
    private_key = "${file(var.private_key_path)}"
  }

  provisioner "remote-exec" {
    inline = [
        "enter scriopt or commands here"
    ]
  }
}

# output

output "aws_public_ip" {
    value = 
    "${aws_instance.ex.public_dns}"
}
