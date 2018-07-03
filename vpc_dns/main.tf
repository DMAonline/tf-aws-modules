variable "domain_name" {
  description = "Zone name, e.g stack.local"
}

variable "vpc_id" {
  description = "The VPC ID (omit to create a public zone)"
}

variable "zone_comment" {
  description = "Comment to add to the DNS zone (optional)"
  default     = ""
}

variable "environment" {
  description = "Environment tag, e.g. sandbox, dev, staging, prod"
}

resource "aws_route53_zone" "main" {
  name    = "${var.domain_name}"
  vpc_id  = "${var.vpc_id}"
  comment = "${var.zone_comment}"

  tags {
    Name        = "${format("vpc_dns-%s", var.domain_name)}"
    Environment = "${var.environment}"
    terraform   = "true"
  }
}

// The domain name.
output "name" {
  value = "${var.domain_name}"
}

// The zone ID.
output "zone_id" {
  value = "${aws_route53_zone.main.zone_id}"
}

// A comma separated list of the zone name servers.
output "name_servers" {
  value = "${join(",",aws_route53_zone.main.name_servers)}"
}
