variable "role_prefix" {
  description = "Prefix to apply to the role generally this is the environment tag, e.g. sandbox, dev, staging, prod"
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

resource "aws_iam_policy" "bastion_assoicate_ip" {
  name   = "${var.role_prefix}-bation-assoicate_ip-policy"
  path   = "/"
  policy = "${data.aws_iam_policy_document.bastion_instance_associate_ip.json}"
}

resource "aws_iam_role_policy_attachment" "bastion_associate_ip" {
  role       = "${aws_iam_role.bastion.name}"
  policy_arn = "${aws_iam_policy.bastion_assoicate_ip.arn}"
}

output "instance_profile_name" {
  value = "${aws_iam_instance_profile.bastion.name}"
}
