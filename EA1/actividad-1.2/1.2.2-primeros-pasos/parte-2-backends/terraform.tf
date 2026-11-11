terraform {
  required_providers {
    random = {
      source = "hashicorp/random"
    }
  }

  backend "s3" {
    bucket = "tf-state-joseyovera-auy1103"
    key    = "prod/aws_infra"
    region = "us-east-1"
  }
}
