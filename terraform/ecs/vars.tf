### Amazon Variable Definitions ####
#Read in from tfvars
variable "accessKey" {
    description = "AWS account access key ID"
}

#Read in from tfvars
variable "secretKey" {
    description = "AWS account secret access key"
}

# Account number (for iam policies)
variable "accountNumber" {
    description = "AWS Account number"
}

# Read from tfvars
variable "provisionerPublicKey" {
    description = "AWS Public Key"
}

#Using the EC2 us-east-1 region because it's a region that I can use.
variable "region1" {
    default     = "us-east-1"
    description = "AWS Region"
}

variable "region1_az1" {
    default     = "us-east-1e"
    description = "AZ1 for region 1"
}

variable "region1_az2" {
    default     = "us-east-1c"
    description = "AZ2 for region 1"
}

#Using the EC2 us-west-1 region for backup.
variable "region2" {
    default     = "us-west-1"
    description = "The region of AWS, for AMI lookups."
}

variable "region2_az1" {
    default     = "us-west-1b"
    description = "AZ for region 1"
}

variable "region2_az2" {
    default     = "us-west-1a"
    description = "AZ for region 1"
}

#Pre-configured DNS delegation set ID
variable "delegationSet" {
    default     = "N3DWCHIKKR8MP4"
    description = "Static delegation created outside of TF"
}

#Call out to icanhazip.com to get my local workstation's external ip, which I can reference as (data.http.icanhazip.body) 
data "http" "icanhazip" {
   url = "http://icanhazip.com"
}

variable "dynamoEndpoint" {
    default     = "com.amazonaws.us-east-1.dynamodb"
    description = "the dynamo DB endpoint to use"
}
