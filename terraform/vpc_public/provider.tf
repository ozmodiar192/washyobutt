# Configure access to AWS as my provider
provider "aws" {
  access_key = "${var.accessKey}"
  secret_key = "${var.secretKey}"
  region     = "${var.region}"
}

provider "aws" {
  alias = "awsAssume"
  region     = "${var.region}"
  assume_role {
    role_arn     = "arn:aws:iam::054218007579:role/AutomationFullAccess"
    session_name = "terraform_provisioning"
  }
}
