variable "instance_type" {
  description = "The instance type for the SSH bastion"
  default     = "t2.nano"
}

variable "security_groups" {
  description = "seperated list of security group ids"
  type        = "list"
}

variable "key_name" {
  description = "The admin SSH key pair, key name"
}

variable "name" {
  description = "The prefix name to give the security groups"
}

variable "environment" {
  description = "Environment tag, e.g. sandbox, dev, staging, prod"
}

variable "keys_update_frequency" {
  description = "Crontab execution time for updating the keys from the S3 bucket"
  default     = "0-59/10 * * * *"                                                 // defaults to every 10 minutes
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

variable "additional_user_data_script" {
  description = "Additonal commands to run in the user data script"
  default     = ""
}

variable "asg_subnet_ids" {
  description = "The subnet ids for the Auto Scaling group"
  default     = []
}

variable "iam_instance_profile_name" {
  description = "IAM Instance profile to assign to bastion instances"
}

# Public EIP for the bastion

resource "aws_eip" "bastion" {
  vpc = true

  tags {
    Name        = "${format("%s-bastion-eip", var.name)}"
    Environment = "${var.environment}"
    terraform   = "true"
  }
}

# This data source returns the newest Amazon 2 instance AMI
data "aws_ami" "amazon2_ami" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami*"]
  }
}

data "template_file" "user_data_script" {
  template = "${file("${path.module}/user_data.template.sh")}"

  vars {
    s3_bucket_uri               = "s3://${var.ssh_public_keys_s3_bucket_name}/${var.ssh_public_keys_s3_bucket_path}"
    ssh_user                    = "ec2-user"
    keys_update_frequency       = "${var.keys_update_frequency}"
    additional_user_data_script = "${var.additional_user_data_script}"
    eip_id                      = "${aws_eip.bastion.id}"
  }
}

# Bastion ASG + Launch Config

resource "aws_launch_configuration" "bastion" {
  name_prefix       = "${var.name}-bastion-"
  image_id          = "${data.aws_ami.amazon2_ami.id}"
  instance_type     = "${var.instance_type}"
  user_data         = "${data.template_file.user_data_script.rendered}"
  enable_monitoring = false

  security_groups = [
    "${var.security_groups}",
  ]

  iam_instance_profile = "${var.iam_instance_profile_name}"
  key_name             = "${var.key_name}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "bastion" {
  name = "${var.name}-asg-bastion"

  vpc_zone_identifier = [
    "${var.asg_subnet_ids}",
  ]

  desired_capacity          = "1"
  min_size                  = "1"
  max_size                  = "1"
  health_check_grace_period = "60"
  health_check_type         = "EC2"
  force_delete              = false
  wait_for_capacity_timeout = 0
  launch_configuration      = "${aws_launch_configuration.bastion.name}"

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
  ]

  tag {
    key                 = "Name"
    value               = "${var.name}-bastion"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "${var.environment}"
    propagate_at_launch = true
  }

  tag {
    key                 = "terraform"
    value               = "true"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# OUTPUTS

# Bastion External IP
output "external_ip" {
  value = "${aws_eip.bastion.public_ip}"
}

output "ssh_user" {
  value = "ec2-user"
}
