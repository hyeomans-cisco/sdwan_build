################# variables ############################################
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "private_key_path" {
    default = "$HOME/.ssh/"
}
variable "key_name" {
    default = "hfy-macpro"
}
variable "vpn_0_isp_1" {
    default = "10.1.0.0/16"
}
variable "vpn_0_isp_2" {
    default = "10.1.1.0/16"
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
# variable "aws_vpc.vpc.id"

################# provider ############################################
provider "aws" {
    # access_key = "${var.aws_access_key}"
    # secret_key = "${var.aws_secret_key}"
    shared_credentials_file = "~/.aws/credentials"
    region = "us-east-1"
}

################# data ############################################

data "aws_availability_zones" "available" {}

variable "avail_zone_name" {
  default = "${data.aws_availability_zones.available.names[0]}"
}


################# resource ############################################
resource "aws_vpc" "sdwan_lab" {
    cidr_block = "${var.vpc_cidr_block}"
    enable_dns_hostnames = "true"

    tags = {
        Name = "${var.aws_vpc_id}-vpc"
    }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = "${aws_vpc.vpc.id}"

    tags = {
        Name = "${var.aws_vpc_id}-igw"
    }
}
resource "aws_subnet" "vpn_0_isp_1" {
    cidr_block = "${var.vpn_0_isp_1}"
    vpc_id = "${aws_vpc.vpc.id}"
    availability_zone = "${var.avail_zone_name}"
}

resource "aws_subnet" "vpn_0_isp_2" {
    cidr_block = "${var.vpn_0_isp_2}"
    vpc_id = "${aws_vpc.vpc.id}"
    availability_zone = "${var.avail_zone_name}"
}

resource "aws_subnet" "vpn_512" {
    cidr_block = "${var.vpn_512}"
    vpc_id = "${aws_vpc.vpc.id}"
    availability_zone = "${var.avail_zone_name}"
}

resource "aws_subnet" "vpn_1" {
    cidr_block = "${ var.vpn_1}"
    vpc_id = "${aws_vpc.vpc.id}"
    availability_zone = "${var.avail_zone_name}"
}

resource "aws_route_table" "rtb" {
    vpc_id = "${aws_vpc.vpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.igw.id}"
    }

    tags {
        Name = "${var.aws_vpc_id}-rtb"
    }
}
##### routing #####
resource "aws_route_table_association" "rta-vpn0-isp1" {
    subnet_id = "${aws_subnet.vpn_0_isp_1}"
}
resource "aws_route_table_association" "rta-vpn0-isp2" {
    subnet_id = "${aws_subnet.vpn_0_isp_2}"
  
}

resource "aws_route_table_association" "rta-vpn512" {
    subnet_id = "${var.vpn_512}"
}

resource "aws_route_table_association" "rta-vpn1" {
    subnet_id = "${var.vpn_1}"
  
}

##### security groups #####

resource "aws_security_group" "sdwan-cisco-ips-sg" {
    name = "sdwan_lab_sg"
    vpc_id = "${aws_vpc.vpc.id}"

    ingress {
        from_port = 8443
        to_port = 8443
        protocol = tcp
        cidr_blocks = ["173.36.0.0/14"]
    }

    ingress {
        from_port = 22
        to_port = 22
        protocol = tcp
        cidr_blocks = ["173.36.0.0/14"]
    }

    ingress {
        from_port = 443
        to_port = 443
        protocol = https
        cidr_blocks = ["173.36.0.0/14"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags {
        Name = "${var.aws_vpc}-sg"
    }
}

resource "network_interface" "vpn0_isp1_int" {
    subnet_id = "${aws_subnet.vpn_0_isp_1.id}"

    tags {
        Name = "vpn0_isp_1_nterface"
    }
}
resource "aws_instance" "vEdge" {
    ami           = "aami-0fb321d472a665c9b"
    instance_type = "c5.xlarge"
    key_name = "${var.key_name}" # key that you're going to use to ssh into the instance using that keypair
    vpc_id = "${aws_vpc.vpc.id}"
    vpc_security_group_ids = ["${aws_security_group.sdwan-cisco-ips-sg.id}"]

  connection {
    user        = "admin"
    private_key = "${file(var.private_key_path)}"
  }

 # provisioner "remote-exec" {
 #   inline = [
 #       "enter scriopt or commands here"
 #   ]
 # }
}

  network_interface {
      network_interface_id = "${network_interface.vpn0_isp1_int}"
      device_index = 0
  }

  network_interface {
      network_interface_id = "${network_interface.}" # left off *********
  }

resource "aws_instance" "vBond" {
    ami           = "ami-0fb321d472a665c9b"
    instance_type = "t2.medium"
    key_name = "${var.key_name}" # key that you're going to use to ssh into the instance using that keypair
    vpc_id = "${aws_vpc.vpc.id}"
    vpc_security_group_ids = ["${aws_security_group.sdwan-cisco-ips-sg.id}"]

  connection {
    user        = "admin"
    private_key = "${file(var.private_key_path)}"
  }

 # provisioner "remote-exec" {
 #   inline = [
 #       "enter scriopt or commands here"
 #   ]
 # }
}

resource "aws_instance" "vSmart" {
    ami           = "ami-009199ca9072fff9b"
    instance_type = "t2.medium"
    key_name = "${var.key_name}" # key that you're going to use to ssh into the instance using that keypair
    vpc_id = "${aws_vpc.vpc.id}"
    vpc_security_group_ids = ["${aws_security_group.sdwan-cisco-ips-sg.id}"]

  connection {
    user        = "admin"
    private_key = "${file(var.private_key_path)}"
  }

 # provisioner "remote-exec" {
 #   inline = [
 #       "enter scriopt or commands here"
 #   ]
 # }
}

resource "aws_instance" "vManage" {
    ami           = "ami-0bec2a918cc4d417b"
    instance_type = "t2.xlarge"
    key_name = "${var.key_name}" # key that you're going to use to ssh into the instance using that keypair
    vpc_id = "${aws_vpc.vpc.id}"
    vpc_security_group_ids = ["${aws_security_group.sdwan-cisco-ips-sg.id}"]

  connection {
    user        = "admin"
    private_key = "${file(var.private_key_path)}"
  }

resource "aws_instance" "Linux_host_vpn1" {
    ami = "ami-00a1270ce1e007c27"
    instance_type = "t2.medium"
    key_name = "${var.key_name}" # key that you're going to use to ssh into the instance using that keypair
    vpc_id = "${aws_vpc.vpc.id}"
    vpc_security_group_ids = ["${aws_security_group.sdwan-cisco-ips-sg.id}"]

    connection {
      user        = "admin"
      private_key = "${file(var.private_key_path)}"    
   }

 # provisioner "remote-exec" {
 #   inline = [
 #       "enter scriopt or commands here"
 #   ]
 # }
}

################# output ############################################

output "aws_public_ip" {
    value = 
    "${aws_instance.ex.public_dns}"
}
