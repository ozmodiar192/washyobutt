# Define the manually-configured s3 and dynamodb tables as the state backend
terraform {
 backend "s3" {
 encrypt        = true
 bucket         = "wyb-state-bucket"
 dynamodb_table = "wyb-tf-state-table"
 region         = "us-east-1"
 key            = "tf_prod_vpcPublic/wyb.tfstate"
 role_arn       = "arn:aws:iam::054218007579:role/AutomationFullAccess"
 }
}
