provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "terraform-github-remotestate-2021"
    key = "organization/terraform-heros/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
    dynamodb_table = "terraform_state_lock_table"
  }
}
provider "github" {
  owner = "terraform-heros"
  token = var.github_token
}
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "github_token" {}
