################# variables ############################################
# variable "aws_access_key" {}
# variable "aws_secret_key" {}
variable "private_key_path" {
    default = "$HOME/.ssh/"
}
variable "key_name" {
    default = "hfy-macpro"
}
variable "vpn_0_isp_1" {
    default = "10.1.0.0/24"
}
variable "vpn_0_isp_2" {
    default = "10.1.1.0/24"
}
variable "vpn_512" {
    default = "10.1.2.0/24"
}
variable "vpn_1" {
    default = "10.1.3.0/24"
}

variable "vpc_cidr_block" {
    default = "10.1.0.0/16"
}

variable "aws_vpc_id" {
    default = "sdwan_lab_aws"
}

################# provider ############################################
provider "aws" {
    shared_credentials_file = "$HOME/.aws/credentials"
    region = "us-east-1"
}

################# data ############################################
data "aws_availability_zones" "available" {}


################# resource ############################################
resource "aws_vpc" "sdwan_lab" {
    cidr_block = "${var.vpc_cidr_block}"
    enable_dns_hostnames = "true"

    tags = {
        Name = "${var.aws_vpc_id}-vpc"
    }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = "${aws_vpc.sdwan_lab.id}"

    tags = {
        Name = "${var.aws_vpc_id}-igw"
    }
}
resource "aws_subnet" "vpn_0_isp_1" {
    cidr_block = "${var.vpn_0_isp_1}"
    vpc_id = "${aws_vpc.sdwan_lab.id}"
    availability_zone = "${data.aws_availability_zones.available.names[1]}"
}

resource "aws_subnet" "vpn_0_isp_2" {
    cidr_block = "${var.vpn_0_isp_2}"
    vpc_id = "${aws_vpc.sdwan_lab.id}"
    availability_zone = "${data.aws_availability_zones.available.names[1]}"
}

resource "aws_subnet" "vpn_512" {
    cidr_block = "${var.vpn_512}"
    vpc_id = "${aws_vpc.sdwan_lab.id}"
    availability_zone = "${data.aws_availability_zones.available.names[1]}"
}

resource "aws_subnet" "vpn_1" {
    cidr_block = "${ var.vpn_1}"
    vpc_id = "${aws_vpc.sdwan_lab.id}"
    availability_zone = "${data.aws_availability_zones.available.names[1]}"
}

resource "aws_route_table" "rtb" {
    vpc_id = "${aws_vpc.sdwan_lab.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.igw.id}"
    }

    tags = {
        Name = "${var.aws_vpc_id}-rtb"
    }
}

##### routing #####
resource "aws_route_table_association" "rta-vpn0-isp1" {
    subnet_id = "${aws_subnet.vpn_0_isp_1.id}"
    route_table_id = "${aws_route_table.rtb.id}"
}
resource "aws_route_table_association" "rta-vpn0-isp2" {
    subnet_id = "${aws_subnet.vpn_0_isp_2.id}"
    route_table_id = "${aws_route_table.rtb.id}"
  
}

resource "aws_route_table_association" "rta-vpn512" {
    subnet_id = "${aws_subnet.vpn_512.id}"
    route_table_id = "${aws_route_table.rtb.id}"
}

resource "aws_route_table_association" "rta-vpn1" {
    subnet_id = "${aws_subnet.vpn_1.id}"
    route_table_id = "${aws_route_table.rtb.id}"
  
}

##### security groups #####

resource "aws_security_group" "sdwan-cisco-ips-sg" {
    name = "sdwan_lab_sg"
    vpc_id = "${aws_vpc.sdwan_lab.id}"

    ingress {
        from_port = 8443
        to_port = 8443
        protocol = "tcp"
        cidr_blocks = ["173.36.0.0/14"]
    }

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["173.36.0.0/14"]
    }

    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["173.36.0.0/14"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.aws_vpc_id}-sg"
    }
}
##### interfaces #####

resource "aws_network_interface" "vpn0_isp1_int" {
    subnet_id = "${aws_subnet.vpn_0_isp_1.id}"

    tags = {
        Name = "vpn0_isp_1_interface"
    }
}
resource "aws_network_interface" "vpn0_isp2_int" {
    subnet_id = "${aws_subnet.vpn_0_isp_1.id}"

    tags = {
        Name = "vpn0_isp_2_interface"
    }
}

resource "aws_network_interface" "vpn512_int" {
    subnet_id = "${aws_subnet.vpn_512.id}"

    tags = {
        Name = "vpn512_interface"
    }
}

resource "aws_network_interface" "vpn1_int" {
    subnet_id = "${aws_subnet.vpn_1.id}"

    tags = {
        Name = "vpn1_interface"
    }
}
resource "aws_instance" "vEdge" {
    ami           = "ami-05049a983484d9ab3"
    instance_type = "c5.xlarge"
    key_name = "${var.key_name}" 

    connection {
      user        = "admin"
      private_key = "${file(var.private_key_path)}"
  }

 # provisioner "remote-exec" {
 #   inline = [
 #       "enter scriopt or commands here"
 #   ]
 #  }
 # }

    network_interface {
      network_interface_id = "${aws_network_interface.vpn0_isp1_int.id}"
      device_index = 0
  }

    network_interface {
      network_interface_id = "${aws_network_interface.vpn0_isp2_int.id}"
      device_index = 1
  }

    network_interface {
      network_interface_id = "${aws_network_interface.vpn512_int.id}"
      device_index = 1
  }

    network_interface {
      network_interface_id = "${aws_network_interface.vpn1_int.id}"
      device_index = 2
  }
}