################# variables ############################################
###### Note: If you wish to use your credentials file in in your .aws config
###### comment out the access and secret key variables below and comment out 
###### the corresponding entries under the aws provider below
variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "private_key_path" {
    default = "$HOME/.ssh/"
}
variable "key_name" {}
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

variable "sen_1" {
    default = "10.1.4.0/24"
}

variable "vpc_cidr_block" {
    default = "10.1.0.0/16"
}

variable "nat_public_block" {
    default = "10.1.5.0/24"
}

###### Define AMIs to use to build instances 
###### Change to match the AMI information for your AWS account

variable "vedge_vbond_ami" {
    default = "ami-0fb321d472a665c9b"
}

variable "vsmart_ami" {
    default = "ami-0bec2a918cc4d417b"
}

variable "vmanage_ami" {
    default = "ami-009199ca9072fff9b"
}

variable "ubuntu_endpoint_ami" {
    default = "ami-0d5d9d301c853a04a"
}

###### Name VPC 

variable "aws_vpc_id" {
    default = "sdwan_lab_aws"
}

################# provider ############################################

provider "aws" {
     access_key = "${var.aws_access_key}"
     secret_key = "${var.aws_secret_key}"
 #   shared_credentials_file = "$HOME/.aws/credentials"
    region = "us-east-1"
}

################# data ############################################

data "aws_availability_zones" "available" {}


################# vpc ############################################

resource "aws_vpc" "sdwan_lab" {
    cidr_block = "${var.vpc_cidr_block}"
    enable_dns_hostnames = "true"

    tags = {
        Name = "${var.aws_vpc_id}-vpc"
    }
}

resource "aws_eip" "nat" {
    vpc = true
    depends_on = ["aws_internet_gateway.igw"]

}

##### internet gateway #####

resource "aws_internet_gateway" "igw" {
    vpc_id = "${aws_vpc.sdwan_lab.id}"

    tags = {
        Name = "${var.aws_vpc_id}-igw"
    }
}


##### subnets #####

resource "aws_subnet" "subnet_vpn_0_isp_1" {
    cidr_block = "${var.vpn_0_isp_1}"
    vpc_id = "${aws_vpc.sdwan_lab.id}"
    availability_zone = "${data.aws_availability_zones.available.names[1]}"
}

resource "aws_subnet" "subnet_vpn_0_isp_2" {
    cidr_block = "${var.vpn_0_isp_2}"
    vpc_id = "${aws_vpc.sdwan_lab.id}"
    availability_zone = "${data.aws_availability_zones.available.names[1]}"
}

resource "aws_subnet" "subnet_vpn_512" {
    cidr_block = "${var.vpn_512}"
    vpc_id = "${aws_vpc.sdwan_lab.id}"
    availability_zone = "${data.aws_availability_zones.available.names[1]}"
    map_public_ip_on_launch = "true"
}

resource "aws_subnet" "subnet_vpn_1" {
    cidr_block = "${ var.vpn_1}"
    vpc_id = "${aws_vpc.sdwan_lab.id}"
    availability_zone = "${data.aws_availability_zones.available.names[1]}"
}

resource "aws_subnet" "subnet_sen_1" {
    cidr_block = "${ var.sen_1}"
    vpc_id = "${aws_vpc.sdwan_lab.id}"
    availability_zone = "${data.aws_availability_zones.available.names[1]}"
}

resource "aws_subnet" "nat_public" {
    cidr_block = "${ var.nat_public_block}"
    vpc_id = "${aws_vpc.sdwan_lab.id}"
    availability_zone = "${data.aws_availability_zones.available.names[1]}"
}


##### nat gateway #####

resource "aws_nat_gateway" "ngw" {
    allocation_id = "${aws_eip.nat.id}"
    subnet_id = "${aws_subnet.nat_public.id}"
    depends_on = ["aws_internet_gateway.igw"]

    tags = {
        Name = "${var.aws_vpc_id}-igw"
    }
}

##### routing #####

resource "aws_route_table" "rtb" {
    vpc_id = "${aws_vpc.sdwan_lab.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_nat_gateway.ngw.id}"
    }

    tags = {
        Name = "${var.aws_vpc_id}-rtb"
    }
}

resource "aws_route_table" "rtb-public" {
    vpc_id = "${aws_vpc.sdwan_lab.id}"

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = "${aws_internet_gateway.ngw.id}"
    }

    tags = {
        Name = "${var.aws_vpc_id}-rtb-pub"
    }
}

resource "aws_route_table_association" "rta-nat-public" {
    subnet_id = "${aws_subnet.nat_public.id}"
    route_table_id = "${aws_route_table.rtb-public.id}"
}

resource "aws_route_table_association" "rta-vpn0-isp1" {
    subnet_id = "${aws_subnet.subnet_vpn_0_isp_1.id}"
    route_table_id = "${aws_route_table.rtb.id}"
}

resource "aws_route_table_association" "rta-vpn0-isp2" {
    subnet_id = "${aws_subnet.subnet_vpn_0_isp_2.id}"
    route_table_id = "${aws_route_table.rtb.id}"
  
}

resource "aws_route_table_association" "rta-vpn512" {
    subnet_id = "${aws_subnet.subnet_vpn_512.id}"
    route_table_id = "${aws_route_table.rtb.id}"
}

resource "aws_route_table_association" "rta-vpn1" {
    subnet_id = "${aws_subnet.subnet_vpn_1.id}"
    route_table_id = "${aws_route_table.rtb.id}"
  
}

resource "aws_route_table_association" "rta-sen" {
    subnet_id = "${aws_subnet.subnet_sen_1.id}"
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
        from_port = 443
        to_port = 443
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

    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["${var.vpc_cidr_block}"]
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

# vEdge01

resource "aws_network_interface" "vedge01_vpn0_isp1_int" {
    subnet_id = "${aws_subnet.subnet_vpn_0_isp_1.id}"
    security_groups = [ "${aws_security_group.sdwan-cisco-ips-sg.id}" ]

    tags = {
        Name = "vedge01_vpn0_isp_1_interface"
    }
}
resource "aws_network_interface" "vedge01_vpn0_isp2_int" {
    subnet_id = "${aws_subnet.subnet_vpn_0_isp_1.id}"
    security_groups = [ "${aws_security_group.sdwan-cisco-ips-sg.id}" ]

    tags = {
        Name = "vedge01_vpn0_isp_2_interface"
    }
}

resource "aws_network_interface" "vedge01_vpn512_int" {
    subnet_id = "${aws_subnet.subnet_vpn_512.id}"
    security_groups = [ "${aws_security_group.sdwan-cisco-ips-sg.id}" ]

    tags = {
        Name = "vedge01_vpn512_interface"
    }
}

resource "aws_network_interface" "vedge01_vpn1_int" {
    subnet_id = "${aws_subnet.subnet_vpn_1.id}"
    security_groups = [ "${aws_security_group.sdwan-cisco-ips-sg.id}" ]

    tags = {
        Name = "vedge01_vpn1_interface"
    }
}

# vEdge02

resource "aws_network_interface" "vedge02_vpn0_isp1_int" {
    subnet_id = "${aws_subnet.subnet_vpn_0_isp_1.id}"
    security_groups = [ "${aws_security_group.sdwan-cisco-ips-sg.id}" ]

    tags = {
        Name = "vedge02_vpn0_isp_1_interface"
    }
}
resource "aws_network_interface" "vedge02_vpn0_isp2_int" {
    subnet_id = "${aws_subnet.subnet_vpn_0_isp_1.id}"
    security_groups = [ "${aws_security_group.sdwan-cisco-ips-sg.id}" ]

    tags = {
        Name = "vedge02_vpn0_isp_2_interface"
    }
}
resource "aws_network_interface" "vedge02_vpn512_int" {
    subnet_id = "${aws_subnet.subnet_vpn_512.id}"
    security_groups = [ "${aws_security_group.sdwan-cisco-ips-sg.id}" ]

    tags = {
        Name = "vedge02_vpn512_interface"
    }
}

resource "aws_network_interface" "vedge02_vpn1_int" {
    subnet_id = "${aws_subnet.subnet_vpn_1.id}"
    security_groups = [ "${aws_security_group.sdwan-cisco-ips-sg.id}" ]

    tags = {
        Name = "vedge02_vpn1_interface"
    }
}

# vBond

resource "aws_network_interface" "vbond_sen_int" {
    subnet_id = "${aws_subnet.subnet_sen_1.id}"
    security_groups = [ "${aws_security_group.sdwan-cisco-ips-sg.id}" ]

    tags = {
        Name = "vbond_sen_interface"
    }
}

resource "aws_network_interface" "vbond_vpn512_int" {
    subnet_id = "${aws_subnet.subnet_vpn_512.id}"
    security_groups = [ "${aws_security_group.sdwan-cisco-ips-sg.id}" ]

    tags = {
        Name = "vbond_vpn512_interface"
    }
}

#vSmart

resource "aws_network_interface" "vsmart_sen_int" {
    subnet_id = "${aws_subnet.subnet_sen_1.id}"
    security_groups = [ "${aws_security_group.sdwan-cisco-ips-sg.id}" ]

    tags = {
        Name = "vsmart_sen_interface"
    }
}

resource "aws_network_interface" "vsmart_vpn512_int" {
    subnet_id = "${aws_subnet.subnet_vpn_512.id}"
    security_groups = [ "${aws_security_group.sdwan-cisco-ips-sg.id}" ]

    tags = {
        Name = "vsmart_vpn512_interface"
    }
}

# vManage

resource "aws_network_interface" "vmanage_sen_int" {
    subnet_id = "${aws_subnet.subnet_sen_1.id}"
    security_groups = [ "${aws_security_group.sdwan-cisco-ips-sg.id}" ]

    tags = {
        Name = "vmanage_sen_interface"
    }
}

resource "aws_network_interface" "vmanage_vpn512_public_int" {
    subnet_id = "${aws_subnet.nat_public.id}"
    security_groups = [ "${aws_security_group.sdwan-cisco-ips-sg.id}" ]

    tags = {
        Name = "vmanage_vpn512_interface"
    }
}

##### ec2 instances #####

# Ubuntu end-point hosts

resource "aws_instance" "ubuntuclient01" {
    ami           = "${var.ubuntu_endpoint_ami}"
    instance_type = "t2.micro"
    key_name = "${var.key_name}"
    subnet_id = "${aws_subnet.subnet_vpn_1.id}"
    security_groups = [ "${aws_security_group.sdwan-cisco-ips-sg.id}" ]

    connection {
      user        = "ubuntu"
      private_key = "${file(var.private_key_path)}"
  }

tags = {
     Name = "ubuntuclient01"
    }

 # provisioner "remote-exec" {
 #   inline = [
 #       "enter script or commands here"
 #   ]
 #  }
 # }
}

 resource "aws_instance" "ubuntuclient02" {
    ami           = "${var.ubuntu_endpoint_ami}"
    instance_type = "t2.micro"
    key_name = "${var.key_name}"
    subnet_id = "${aws_subnet.subnet_vpn_1.id}"
    security_groups = [ "${aws_security_group.sdwan-cisco-ips-sg.id}" ]

    connection {
      user        = "ubuntu"
      private_key = "${file(var.private_key_path)}"
  }

  tags = {
        Name = "ubuntuclient02"
    }

 # provisioner "remote-exec" {
 #   inline = [
 #       "enter script or commands here"
 #   ]
 #  }
 # }
 }

resource "aws_instance" "jumphost01" {
    ami           = "${var.ubuntu_endpoint_ami}"
    instance_type = "t2.micro"
    key_name = "${var.key_name}"
    subnet_id = "${aws_subnet.nat_public.id}"
    security_groups = [ "${aws_security_group.sdwan-cisco-ips-sg.id}" ]
    associate_public_ip_address = true

    connection {
      user        = "ubuntu"
      private_key = "${file(var.private_key_path)}"
  }
  tags = {
        Name = "jumphost01"
    }
 # provisioner "remote-exec" {
 #   inline = [
 #       "enter script or commands here"
 #   ]
 #  }
 # }
}

output "aws_public_ip" {
    value = "${aws_instance.jumphost01.public_dns}"
}

# resource "aws_eip" "pub_jumphost01" {
#   vpc = true
#   instance = "${aws_instance.jumphost01}"
#   depends_on = ["aws_internet_gateway.igw"]

# }

# vEdge01

resource "aws_instance" "vedge01" {
    ami           = "${var.vedge_vbond_ami}"
    instance_type = "m4.xlarge"
    key_name = "${var.key_name}"

    connection {
      user        = "admin"
      private_key = "${file(var.private_key_path)}"
  }

 # provisioner "remote-exec" {
 #   inline = [
 #       "enter script or commands here"
 #   ]
 #  }
 # }

    network_interface {
      network_interface_id = "${aws_network_interface.vedge01_vpn512_int.id}"
      device_index = 0
  }

    network_interface {
      network_interface_id = "${aws_network_interface.vedge01_vpn0_isp1_int.id}"
      device_index = 1
  }

    network_interface {
      network_interface_id = "${aws_network_interface.vedge01_vpn0_isp2_int.id}"
      device_index = 2
  }

    network_interface {
      network_interface_id = "${aws_network_interface.vedge01_vpn1_int.id}"
      device_index = 3
  }
  tags = {
        Name = "vEdge01"
    }
}

data "aws_network_interface" "vedge01_vpn" {
    filter {
        name = "tag:Name"
        values = ["vedge01_vpn512_interface"]
    }

    depends_on = ["aws_network_interface.vedge01_vpn512_int"]
}

#  resource "aws_eip" "pub_sdwan_vedge01" {
#     vpc = true
#     network_interface = "${aws_network_interface.vedge01_vpn512_int.id}"
#     depends_on = ["aws_internet_gateway.igw"]
# 
#  }

# vEdge02

resource "aws_instance" "vedge02" {
    ami           = "${var.vedge_vbond_ami}"
    instance_type = "m4.xlarge"
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
      network_interface_id = "${aws_network_interface.vedge02_vpn512_int.id}"
      device_index = 0
  }

    network_interface {
      network_interface_id = "${aws_network_interface.vedge02_vpn0_isp1_int.id}"
      device_index = 1
  }

    network_interface {
      network_interface_id = "${aws_network_interface.vedge02_vpn0_isp2_int.id}"
      device_index = 2
  }

    network_interface {
      network_interface_id = "${aws_network_interface.vedge02_vpn1_int.id}"
      device_index = 3
  }
  tags = {
        Name = "vEdge02"
    }
}

data "aws_network_interface" "vedge02_vpn_512" {
    filter {
        name = "tag:Name"
        values = ["vedge02_vpn512_interface"]
    }
        
    depends_on = ["aws_network_interface.vedge02_vpn512_int"]
}

# resource "aws_eip" "pub_sdwan_vedge02" {
#    vpc = true
#    network_interface = "${aws_network_interface.vedge02_vpn512_int.id}"
#    depends_on = ["aws_internet_gateway.igw"]
# 
# }

# vBond

resource "aws_instance" "vbond" {
    ami           = "${var.vedge_vbond_ami}"
    instance_type = "t2.medium"
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
      network_interface_id = "${aws_network_interface.vbond_vpn512_int.id}"
      device_index = 0
  }

    network_interface {
      network_interface_id = "${aws_network_interface.vbond_sen_int.id}"
      device_index = 1
  }
  tags = {
        Name = "vBond01"
    }
}

data "aws_network_interface" "vbond_vpn512_int" {
    filter {
        name = "tag:Name"
        values = ["vbond_vpn512_interface"]
    }
        
    depends_on = ["aws_network_interface.vbond_vpn512_int"]
}

 # resource "aws_eip" "pub_sdwan_vbond" {
 #   vpc = true
 #   network_interface = "${aws_network_interface.vbond_vpn512_int.id}"
 #   depends_on = ["aws_internet_gateway.igw"]
 #
 # }

# vSmart

resource "aws_instance" "vsmart" {
    ami           = "${var.vsmart_ami}"
    instance_type = "t2.medium"
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
      network_interface_id = "${aws_network_interface.vsmart_vpn512_int.id}"
      device_index = 0
  }

    network_interface {
      network_interface_id = "${aws_network_interface.vsmart_sen_int.id}"
      device_index = 1
  }

  tags = {
        Name = "vSmart"
    }
}

data "aws_network_interface" "vsmart_vpn512_int" {
    filter {
        name = "tag:Name"
        values = ["vsmart_vpn512_interface"]
    }
        
    depends_on = ["aws_network_interface.vsmart_vpn512_int"]
}

# resource "aws_eip" "pub_sdwan_vsmart" {
#    vpc = true
#    network_interface = "${aws_network_interface.vsmart_vpn512_int.id}"
#    depends_on = ["aws_internet_gateway.igw"]
 
# }

# vManage

resource "aws_instance" "vmanage" {
    ami           = "${var.vmanage_ami}"
    instance_type = "m4.xlarge"
    key_name = "${var.key_name}" 

    connection {
      type        = "ssh"
      user        = "admin"
      password    = "admin"
      host        = "${aws_eip.pub_sdwan_vmanage.public_ip}"
      private_key = "${file("~/.ssh/${var.key_name}.pem")}"
  }

    network_interface {
      network_interface_id = "${aws_network_interface.vmanage_vpn512_public_int.id}"
      device_index = 0
  }

    network_interface {
      network_interface_id = "${aws_network_interface.vmanage_sen_int.id}"
      device_index = 1
  }

  tags = {
        Name = "vManage"
    }

  provisioner "remote-exec" {
   inline = [
       "config t",
       "exit",
       "show run",
   ]
  }
}

data "aws_network_interface" "vmanage_vpn512_int" {
    filter {
        name = "tag:Name"
        values = ["vmanage_vpn512_interface"]
    }
        
    depends_on = ["aws_network_interface.vmanage_vpn512_int"]
}

resource "aws_eip" "pub_sdwan_vmanage" {
    vpc = true
    network_interface = "${aws_network_interface.vmanage_vpn512_public_int.id}"
    depends_on = ["aws_internet_gateway.igw"]

}


