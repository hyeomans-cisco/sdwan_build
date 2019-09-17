##### interfaces #####

resource "network_interface" "vpn0_isp1_int" {
    subnet_id = "${aws_subnet.vpn_0_isp_1.id}"

    tags {
        Name = "vpn0_isp_1_interface"
    }
resource "network_interface" "vpn0_isp2_int" {
    subnet_id = "${aws_subnet.vpn_0_isp_1.id}"

    tags {
        Name = "vpn0_isp_2_interface"
    }

resource "network_interface" "vpn512_int" {
    subnet_id = "${aws_subnet.vpn_512.id}"

    tags {
        Name = "vpn512_interface"
    }

resource "network_interface" "vpn1_int" {
    subnet_id = "${aws_subnet.vpn_1.id}"

    tags {
        Name = "vpn1_interface"
    }
}