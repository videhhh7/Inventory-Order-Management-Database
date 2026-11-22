variable "aws_region" { type = string, default = "ap-south-1" }
variable "name" { type = string, default = "inventory-api-demo" }
variable "image_uri" { type = string }
variable "db_password" { type = string, sensitive = true }
variable "db_username" { type = string, default = "inventoryadmin" }
variable "db_instance_class" { type = string, default = "db.t3.small" }
variable "db_allocated_storage" { type = number, default = 20 }
