terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 4.61"
        }
    }
}

provider "aws" {
    region = "us-east-2"
    access_key = "ACCESS_KEY"
    secret_key = "SECRET_KEY"
}

provider "archive" {
}