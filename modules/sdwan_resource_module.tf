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