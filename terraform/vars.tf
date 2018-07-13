### Amazon Variable Definitions ####
#Read in from tfvars
variable "accessKey" {
    description = "AWS account access key ID"
}

#Read in from tfvars
variable "secretKey" {
    description = "AWS account secret access key"
}

#Using the EC2 us-east-1 region because it's a region that I can use.
variable "region" {
    default     = "us-east-1"
    description = "The region of AWS, for AMI lookups."
}

#The public key for access purposes
variable "publicKey" {
    default    = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDavVobOCvjgfSvVfFS6pO6CsJqIgtouPaLRy9cu209EqYQbh9yGIgOGQhtGSk1zlq3dM1J5Al76mER+WptDMotbojasnfDpQCV+5UK1y2faYPj5j81oqEsO0xIzs7m+yOe8VmK3h43fJyX4xP8hX/aL5U9YjMlcX7xGOZTXCEjYwbSr4xh4effZD+qHnogsZsAJmJY1cbv0q1nZ3tQoAWfO12oYYjjZqWXEpsxPcAUE4hxgnAL7sRGE1grxzYC6ZYbA2Wb4j3tG+qEjpkIOy5/9GarnD4jfGzVpb8UPvtnkUATYs29cIYZQ/5SkTOobXRucvaRc1ZGwfwRUXRF+ozq1OondUG8IEtrFhelVCyHOUCQkKqL50bZ4O7hs1YMmuEZjyYImbfrwrAtqaq5kvVXtrDMhdoOy0N6Z8g2hSAh8hZDhSyZ0nL/d4Hrb+apiwriqpgPq91TsA7LgZxCYoS5blcB3ovW6Xy5xF3wQBbx4P+0RwSE5hJooTb5vZ083erdY8iyxQwlpYgapVTgWov/KZ79DAOFyNb6cK+jQTYAUfsXnhj5lnRDRBxppYENwBSLTd6ABp/12PsodO/Ni/pjzL5drBMODf+X1xdrCb+DeO1mpv+zljnJd8wUyVzEdYeWX4f8w1nvh/TPfyyMLezqlFtoVEJ9LjFT7Li33eK1Dw== mattdherrick@gmail.com"
    description = "The public key for the ec2 keypair"
}

#Call out to icanhazip.com to get my local workstation's external ip, which I can reference as (data.http.icanhazip.body) 
data "http" "icanhazip" {
   url = "http://icanhazip.com"
}
