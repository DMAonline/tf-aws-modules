# VARIABLES

variable "name" {
  description = "The prefix name to give the security groups"
}

variable "vpc_id" {
  description = "The ID of the VPC to associate these security groups with"
}

variable "environment" {
  description = "Environment tag, e.g. sandbox, dev, staging, prod"
}

variable "cidr" {
  description = "The CIDR block to use for internal security groups"
}

variable "ssh_admin_cidr" {
  description = "CIDR to allow external ssh into bastion instances from"
  default     = ""
}

# SECURITY GROUPS

resource "aws_security_group" "external_ssh" {
  name        = "${format("%s-external-ssh", var.name)}"
  vpc_id      = "${var.vpc_id}"
  description = "Allows ssh from admin cidr block"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = "${list(var.ssh_admin_cidr)}"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags {
    Name        = "${format("%s-external-ssh", var.name)}"
    Environment = "${var.environment}"
    terraform   = "true"
  }
}

resource "aws_security_group" "internal_ssh" {
  name        = "${format("%s-internal-ssh", var.name)}"
  vpc_id      = "${var.vpc_id}"
  description = "Allows ssh from bastion"

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = ["${aws_security_group.external_ssh.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr}"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags {
    Name        = "${format("%s-internal-ssh", var.name)}"
    Environment = "${var.environment}"
    terraform   = "true"
  }
}

# OUTPUTS

output "external_ssh" {
  value = "${aws_security_group.external_ssh.id}"
}

output "internal_ssh" {
  value = "${aws_security_group.internal_ssh.id}"
}
