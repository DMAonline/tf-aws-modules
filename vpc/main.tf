variable "cidr" {
  description = "The CIDR block for the VPC"
}

variable "name" {
  description = "Name tag, e.g. operations"
}

variable "environment" {
  description = "Environment tag, e.g. sandbox, dev, staging, prod"
}

# VPC

resource "aws_vpc" "main" {
  cidr_block           = "${var.cidr}"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags {
    Name        = "${var.name}"
    Environment = "${var.environment}"
    terraform   = "true"
  }
}

# Gateways

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name        = "${var.name}"
    Environment = "${var.environment}"
    terraform   = "true"
  }
}

# Route Tables

resource "aws_route_table" "external" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name        = "${var.name}-external-001"
    Environment = "${var.environment}"
    terraform   = "true"
  }
}

resource "aws_route" "external" {
  route_table_id         = "${aws_route_table.external.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.main.id}"
}

# OUTPUTS

output "vpc_id" {
  value = "${aws_vpc.main.id}"
}

output "vpc_cidr_block" {
  value = "${aws_vpc.main.cidr_block}"
}

output "vpc_security_group" {
  value = "${aws_vpc.main.default_security_group_id}"
}

output "vpc_igw_id" {
  value = "${aws_internet_gateway.main.id}"
}

output "external_route_table_id" {
  value = "${aws_route_table.external.id}"
}
