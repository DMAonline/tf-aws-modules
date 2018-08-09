variable "name" {
  description = "Name to give the peering connection"
}

variable "environment" {
  description = "Environment tag, e.g. sandbox, dev, staging, prod"
}

variable "peer_mode" {
  description = "Mode to manage the peer connection as, either requester or accepter"
}

variable "vpc_id" {
  description = "The ID of the VPC requesting the peering connection"
  default     = ""
}

variable "peer_vpc_id" {
  description = "The ID of VPC to peer to"
  default     = ""
}

variable "peer_owner_id" {
  description = "The ID of the account that owns the VPC you are requesting a peer to"
  default     = ""
}

variable "peer_region" {
  description = "The region that the peer connection is in"
  default     = ""
}

variable "vpc_peering_connection_id" {
  description = "ID of the peering connection to accept and create accepter routes in"
  default     = ""
}

variable "route_tables" {
  description = "List of route table IDs to create routes for the peering connection"
  default     = []
}

variable "destination_cidr_block" {
  description = "CIDR block to create route for in the route tables over the peering connection"
  default     = ""
}

locals {
  booleans     = "${map("true", true, "false", false)}"
  is_requester = "${var.peer_mode == "requester" ? true : false}"
  is_accepter  = "${var.peer_mode == "accepter" ? true : false}"
}

resource "aws_vpc_peering_connection" "requester_peering_connection" {
  count         = "${local.is_requester}"
  vpc_id        = "${var.vpc_id}"
  peer_vpc_id   = "${var.peer_vpc_id}"
  peer_owner_id = "${var.peer_owner_id}"
  peer_region   = "${var.peer_region}"
  auto_accept   = false

  tags {
    Name        = "${var.name}"
    VPCPeerSide = "Requester"
    Environemnt = "${var.environment}"
    terraform   = "true"
  }
}

resource "aws_vpc_peering_connection_accepter" "accepter_peering_connection" {
  count                     = "${local.is_accepter}"
  vpc_peering_connection_id = "${var.vpc_peering_connection_id}"
  auto_accept               = true

  tags {
    Name        = "${var.name}"
    VPCPeerSide = "Accepter"
    Environemnt = "${var.environment}"
    terraform   = "true"
  }
}

resource "aws_route" "requester" {
  count                     = "${local.is_requester ? length() : 0}"
  route_table_id            = "${element(var.route_tables, count.index)}"
  destination_cidr_block    = "${var.destination_cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.requester_peering_connection.id}"
}

resource "aws_route" "accepter" {
  count                     = "${local.is_accepter ? length() : 0}"
  route_table_id            = "${element(var.route_tables, count.index)}"
  destination_cidr_block    = "${var.destination_cidr_block}"
  vpc_peering_connection_id = "${var.vpc_peering_connection_id}"
}

output "vpc_peering_connection_id" {
  value = "${local.is_requester ? aws_vpc_peering_connection.requester_peering_connection.id : var.vpc_peering_connection_id}"
}
