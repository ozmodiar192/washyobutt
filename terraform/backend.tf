# create a terraform backend that uses the S3 bucket.  This is what actually stores the state
terraform {
 backend "s3" {
 encrypt = true
 bucket = "wyb-state-bucket"
 dynamodb_table = "wyb-tf-state-table"
 region = "us-east-1"
 key = "tf_prod/wyb.tfstate"
 }
}
