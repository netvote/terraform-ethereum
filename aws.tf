provider "aws" {
  profile                 = "netvote"
  shared_credentials_file = "$HOME/.aws/credentials"
  region                  = "us-east-1"
}

variable "environment" {
  type    = "string"
  default = "Ethereum"
}

variable "owner" {
  type    = "string"
  default = "slanders"
}

variable "managedBy" {
  type    = "string"
  default = "terraform"
}

variable "keyName" {
  type    = "string"
  default = "netvote-ethereum"
}

variable "ethNodeType" {
  type    = "string"
  default = "t2.micro"
}

variable "ami" {
  type    = "string"
  default = "ami-467ca739"
}
