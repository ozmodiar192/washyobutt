### Amazon Variable Definitions ####
#Read in from tfvars
variable "accessKey" {
    description = "AWS account access key ID"
}

#Read in from tfvars
variable "secretKey" {
    description = "AWS account secret access key"
}

# Read from tfvars
variable "publicKey" {
    description = "AWS Public Key"
}

#Using the EC2 us-east-1 region because it's a region that I can use.
variable "region" {
    default     = "us-east-1"
    description = "The region of AWS, for AMI lookups."
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
