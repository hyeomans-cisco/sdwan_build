# variables
variable "aws_access_key" {}
variable "aws_secret_key" {}

# provider
provider "aws" {
    shared_credentials_file = "~/.aws/crednetials"
    region = "us-east-1"
}

# resource

# output

