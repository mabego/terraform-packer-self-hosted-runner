provider "aws" {
  region = var.region
  default_tags {
    tags = {
      type = "runner"
    }
  }
}
