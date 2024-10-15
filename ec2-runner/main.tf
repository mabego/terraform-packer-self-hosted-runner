resource "aws_ssm_parameter" "github_pat" {
  name  = "github_pat"
  type  = "SecureString"
  value = var.github_pat

  tags = {
    type = "runner"
  }
}

data "aws_ami" "runner" {
  owners = ["self"]

  filter {
    name   = "tag:type"
    values = ["runner"]
  }


  filter {
    name   = "tag:build"
    values = ["ubuntu-buildah"]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "asg_runner" {
  source = "terraform-aws-modules/autoscaling/aws"

  name = "runner-asg"

  min_size                  = 0
  max_size                  = 1
  desired_capacity          = 1
  wait_for_capacity_timeout = 0
  health_check_type         = "EC2"
  availability_zones        = data.aws_availability_zones.available.names

  initial_lifecycle_hooks = [
    {
      name                 = "RunnerTerminationLifeCycleHook"
      default_result       = "CONTINUE"
      heartbeat_timeout    = 180
      lifecycle_transition = "autoscaling:EC2_INSTANCE_TERMINATING"
    }
  ]

  image_id      = data.aws_ami.runner.id
  instance_type = var.instance_type

  create_iam_instance_profile = true
  iam_role_description        = "EC2 Actions Runner"
  iam_role_name               = "ec2-runner"
  iam_role_policies           = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  tags = {
    type = "runner"
  }
}
