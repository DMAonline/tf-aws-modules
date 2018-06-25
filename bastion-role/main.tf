variable "role_prefix" {
  description = "Prefix to apply to the role generally this is the environment tag, e.g. sandbox, dev, staging, prod"
}

variable "ssh_public_keys_s3_bucket_arn" {
  description = "ARN to the s3 bucket storing the ssh public keys for the organisation"
}

variable "ssh_public_keys_s3_bucket_name" {
  description = "Name of the s3 bucket storing the ssh public keys for the organisation"
}

variable "ssh_public_keys_s3_bucket_path" {
  description = "Path to the directory within the bucket storing the public keys to import to the bastion"
  default     = ""
}

# AWS Instance profile + roles

resource "aws_iam_instance_profile" "bastion" {
  name = "${var.role_prefix}-bastion"
  role = "${var.role_prefix}-bastion-role"
}

data "aws_iam_policy_document" "bastion_instance_assume_role" {
  statement {
    sid = "${var.role_prefix}BastionEc2AssumeRolePolicy"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "bastion" {
  name               = "${var.role_prefix}-bastion-role"
  path               = "/"
  assume_role_policy = "${data.aws_iam_policy_document.bastion_instance_assume_role.json}"
}

data "aws_iam_policy_document" "bastion_instance_associate_ip" {
  statement {
    sid = "${var.role_prefix}BastionEc2AssociateIp"

    actions = [
      "ec2:AssociateAddress",
    ]

    resources = ["*"]
  }
}

data "aws_iam_policy_document" "bastion_instance_s3_public_keys" {
  statement {
    sid = "${var.role_prefix}BastionS3PublicKeys"

    actions = [
      "s3:List*",
      "s3:Get*",
    ]

    resources = ["${var.ssh_public_keys_s3_bucket_arn}/${var.ssh_public_keys_s3_bucket_path}/*"]
  }

  statement {
    actions = [
      "s3:List*",
    ]

    resources = ["${var.ssh_public_keys_s3_bucket_arn}"]
  }
}

resource "aws_iam_policy" "bastion_assoicate_ip" {
  name   = "${var.role_prefix}-bation-assoicate_ip-policy"
  path   = "/"
  policy = "${data.aws_iam_policy_document.bastion_instance_associate_ip.json}"
}

resource "aws_iam_policy" "bastion_s3_public_keys_bucket" {
  name   = "${var.role_prefix}-bation-s3_public_keys-policy"
  path   = "/"
  policy = "${data.aws_iam_policy_document.bastion_instance_s3_public_keys.json}"
}

resource "aws_iam_role_policy_attachment" "bastion_associate_ip" {
  role       = "${aws_iam_role.bastion.name}"
  policy_arn = "${aws_iam_policy.bastion_assoicate_ip.arn}"
}

resource "aws_iam_role_policy_attachment" "bastion_s3_public_keys" {
  role       = "${aws_iam_role.bastion.name}"
  policy_arn = "${aws_iam_policy.bastion_s3_public_keys_bucket.arn}"
}

output "instance_profile_name" {
  value = "${aws_iam_instance_profile.bastion.name}"
}
