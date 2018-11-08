# Configure access to AWS as my provider
provider "aws" {
  region     = "${var.region1}"
  access_key = "${var.accessKey}"
  secret_key = "${var.secretKey}"
  assume_role {
    role_arn     = "arn:aws:iam::054218007579:role/AutomationFullAccess"
    session_name = "terraform_provisioning"
  }
}
