variable "github_pat" {
  type = string
}

variable "instance_type" {
  default = "t2.micro"
  type    = string
}

variable "region" {
  description = "AWS region"
  default     = "us-west-2"
  type        = string
}
