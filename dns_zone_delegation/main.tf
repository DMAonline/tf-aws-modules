variable "zone_id" {
  description = "ID of the Zone to create the delegation in"
  type        = "string"
}

variable "delegation_dns_name" {
  description = "DNS name to create the NS delegation for"
  type        = "string"
}

variable "delegation_ttl" {
  description = "TTL for the DNS delegation"
  default     = "30"
}

variable "delegation_nameservers" {
  description = "List of nameservers to use for the delegation"
  default     = []
  type        = "list"
}

resource "aws_route53_record" "delegation_ns" {
  zone_id = "${var.zone_id}"
  name    = "${var.delegation_dns_name}"
  type    = "NS"
  ttl     = "${var.delegation_ttl}"

  records = ["${var.delegation_nameservers}"]
}

output "delegation_name" {
  description = "Name of the delegation record"
  value       = "${aws_route53_record.delegation_ns.name}"
}

output "delegation_fqdn" {
  description = "FQDN of the delegation record"
  value       = "${aws_route53_record.delegation_ns.fqdn}"
}
