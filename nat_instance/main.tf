variable "internal_cidrs" {
  description = "List of internal CIDRs to provision security group for"
  type        = "list"
}

variable "external_subnet_id" {
  description = "ID of the external subnet to provision in"
}

variable "availability_zone" {
  description = "Availability zone to provision in"
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

variable "vpc_id" {
  description = "ID of the VPC in which to create the security group"
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

resource "aws_security_group" "nat_instance" {
  name        = "nat-${var.name}"
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

  vpc_id = "${var.vpc_id}"
}

resource "aws_instance" "nat_instance" {
  availability_zone = "${var.availability_zone}"

  depends_on = [
    "aws_security_group.nat_instance",
  ]

  tags {
    Name        = "${var.name}"
    Environment = "${var.environment}"
    terraform   = "true"
  }

  volume_tags {
    Name        = "${var.name}"
    Environment = "${var.environment}"
    terraform   = "true"
  }

  key_name          = "${var.nat_instance_ssh_key_name}"
  ami               = "${data.aws_ami.nat_ami.id}"
  instance_type     = "${var.nat_instance_type}"
  source_dest_check = false

  subnet_id = "${var.external_subnet_id}"

  vpc_security_group_ids = ["${aws_security_group.nat_instance.id}"]

  lifecycle {
    ignore_changes = ["ami"]
  }
}

output "security_group_id" {
  value = "${aws_security_group.nat_instance.id}"
}

output "instance_id" {
  value = "${aws_instance.nat_instance.id}"
}
