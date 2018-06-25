variable "name" {
  description = "Name to give the route table"
}

variable "environment" {
  description = "Environment tag, e.g. sandbox, dev, staging, prod"
}

variable "nat_instance_id" {
  description = "ID of NAT instance to route traffic through"
}

variable "vpc_id" {
  description = "The ID of the VPC to setup DHCP for"
}

resource "aws_route_table" "internal" {
  vpc_id = "${var.vpc_id}"

  tags {
    Name        = "${var.name}"
    Environment = "${var.environment}"
    terraform   = "true"
  }
}

resource "aws_route" "default_internal_nat_instance" {
  route_table_id         = "${aws_route_table.internal.id}"
  destination_cidr_block = "0.0.0.0/0"
  instance_id            = "${var.nat_instance_id}"
}

output "route_table_id" {
  value = "${aws_route_table.internal.id}"
}
