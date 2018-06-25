variable "internal_cidrs" {
  description = "List of internal CIDRs to provision security group for"
  type        = "list"
}

variable "external_subnet_ids" {
  description = "List of IDs of the external subnets to provision in"
  type        = "list"
}

variable "nat_instance_count" {
  description = "Number of NAT instances to provison, must not exceed the number of availability zones and external subnet ids specified"
  default     = 1
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = "list"
}

variable "name" {
  description = "Name tag, e.g. operations"
}

variable "environment" {
  description = "Environment tag, e.g. sandbox, dev, staging, prod"
}

variable "nat_instance_type" {
  description = "Which EC2 instance type to use for the NAT instances."
  default     = "t2.nano"
}

variable "nat_instance_ssh_key_name" {
  description = "The optional SSH key-pair to assign to NAT instances."
  default     = ""
}

# This data source returns the newest Amazon NAT instance AMI
data "aws_ami" "nat_ami" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn-ami-vpc-nat*"]
  }
}

resource "aws_security_group" "nat_instances" {
  name        = "nat"
  description = "Allow traffic from clients into NAT instances"

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = "${var.internal_cidrs}"
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = "${var.internal_cidrs}"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_instance" "nat_instance" {
  count             = "${var.nat_instance_count}"
  availability_zone = "${element(var.availability_zones, count.index)}"

  depends_on = [
    "aws_security_group.nat_instances",
  ]

  tags {
    Name        = "${var.name}-${format("internal-%03d-NAT", count.index+1)}"
    Environment = "${var.environment}"
    terraform   = "true"
  }

  volume_tags {
    Name        = "${var.name}-${format("internal-%03d-NAT", count.index+1)}"
    Environment = "${var.environment}"
    terraform   = "true"
  }

  key_name          = "${var.nat_instance_ssh_key_name}"
  ami               = "${data.aws_ami.nat_ami.id}"
  instance_type     = "${var.nat_instance_type}"
  source_dest_check = false

  subnet_id = "${element(var.external_subnet_ids, count.index)}"

  vpc_security_group_ids = ["${aws_security_group.nat_instances.id}"]

  lifecycle {
    ignore_changes = ["ami"]
  }
}
