variable "domain_name" {
  description = "The domain name to setup DHCP for"
}

variable "vpc_id" {
  description = "The ID of the VPC to setup DHCP for"
}

variable "dns_servers" {
  description = "A comma separated list of the IP addresses of internal DHCP servers"
}

resource "aws_vpc_dhcp_options" "dns_resolver" {
  domain_name         = "${var.domain_name}"
  domain_name_servers = ["${split(",", var.dns_servers)}"]
}

resource "aws_vpc_dhcp_options_association" "dns_resolver" {
  vpc_id          = "${var.vpc_id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.dns_resolver.id}"
}
