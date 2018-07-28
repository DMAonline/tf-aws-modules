variable "name" {
  description = "Name to give the route table"
}

variable "environment" {
  description = "Environment tag, e.g. sandbox, dev, staging, prod"
}

variable "vpc_id" {
  description = "The ID of the VPC to setup DHCP for"
}

variable "subnet_cidr" {
  description = "CIDR of the subnet to create"
}

variable "subnet_az" {
  description = "Availability zone to create the subnet in"
}

variable "route_table_id" {
  description = "The ID route table to associate the subnet table with"
}

variable "subnet_tags" {
  default = {}
  type    = "map"
}

resource "aws_subnet" "internal" {
  vpc_id            = "${var.vpc_id}"
  cidr_block        = "${var.subnet_cidr}"
  availability_zone = "${var.subnet_az}"

  tags = "${merge(map("Name", format("%s", var.name), "Environment", format("%s", var.environment), "terraform", "true"), var.subnet_tags)}"
}

resource "aws_route_table_association" "internal" {
  subnet_id      = "${aws_subnet.internal.id}"
  route_table_id = "${var.route_table_id}"
}

output "subnet_id" {
  value = "${aws_subnet.internal.id}"
}
