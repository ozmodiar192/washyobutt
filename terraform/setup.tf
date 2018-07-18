provider "aws" {
  access_key = "${var.accessKey}"
  secret_key = "${var.secretKey}"
  region     = "${var.region}"
}

# create an S3 bucket for the terraform state file
resource "aws_s3_bucket" "state_bucket" {
    bucket = "wyb-state-bucket"
    versioning {
      enabled = true
    }
    lifecycle {
      prevent_destroy = true
    }
    tags {
      Name = "state"
    }      
}

# create a dynamodb table for locking the state file
resource "aws_dynamodb_table" "wyb_tf_state_table" {
  name = "wyb-tf-state-table"
  hash_key = "LockID"
  read_capacity = 20
  write_capacity = 20
 
  attribute {
    name = "LockID"
    type = "S"
  }
 
  tags {
    Name = "DynamoDB Terraform State Lock Table"
  }
}

 create a terraform backend that uses the S3 bucket.
terraform {
 backend "s3" {
 encrypt = true
 bucket = "wyb-state-bucket"
 dynamodb_table = "wyb-tf-state-table"
 region = "us-east-1"
 key = "terraform/wyb.tfstate"
 }
}
