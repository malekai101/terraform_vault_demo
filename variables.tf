variable "linux_image_id" {
  type    = string
  default = "ami-026dea5602e368e96"
}

variable "db_pass" {
  type = string
}

variable "db_user" {
  type = string
}

variable "region" {
  type    = string
  default = "us-east-2"
}

variable "project_name" {
  type    = string
  default = "Vault Football Demo"
}