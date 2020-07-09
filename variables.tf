
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

variable "admin_ip" {
  type = string
}

variable "key" {
  type = string
}