ariable "name" {
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

variable "map_public_ip_on_launch" {
  default = true
}

variable "route_table_id" {
  description = "The ID route table to associate the subnet table with"
}

resource "aws_subnet" "external" {
  vpc_id                  = "${var.vpc_id}"
  cidr_block              = "${var.subnet_cidr}"
  availability_zone       = "${var.subnet_az}"
  map_public_ip_on_launch = "${var.map_public_ip_on_launch}"

  tags {
    Name        = "${var.name}"
    Environment = "${var.environment}"
    terraform   = "true"
  }
}

resource "aws_route_table_association" "external" {
  subnet_id      = "${aws_subnet.external.id}"
  route_table_id = "${var.route_table_id}"
}

output "subnet_id" {
  value = "${aws_subnet.external.id}"
}
