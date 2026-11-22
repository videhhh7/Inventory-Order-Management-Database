terraform {
  required_version = ">= 1.6.0"
  required_providers { aws = { source = "hashicorp/aws", version = "~> 5.0" } }
}
provider "aws" { region = var.aws_region }
data "aws_vpc" "default" { default = true }
data "aws_subnets" "default" { filter { name = "vpc-id" values = [data.aws_vpc.default.id] } }
resource "aws_security_group" "app" {
  name = "${var.name}-app"
  vpc_id = data.aws_vpc.default.id
  ingress { from_port = 8080 to_port = 8080 protocol = "tcp" cidr_blocks = ["0.0.0.0/0"] }
  egress { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }
}
resource "aws_security_group" "db" {
  name = "${var.name}-db"
  vpc_id = data.aws_vpc.default.id
  ingress { from_port = 1433 to_port = 1433 protocol = "tcp" security_groups = [aws_security_group.app.id] }
  egress { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }
}
resource "aws_db_subnet_group" "db" {
  name = "${var.name}-subnets"
  subnet_ids = data.aws_subnets.default.ids
}
resource "aws_db_instance" "sqlserver" {
  identifier = var.name
  engine = "sqlserver-ex"
  engine_version = "15.00"
  instance_class = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  username = var.db_username
  password = var.db_password
  port = 1433
  db_subnet_group_name = aws_db_subnet_group.db.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible = false
  storage_encrypted = true
  backup_retention_period = 1
  skip_final_snapshot = true
}
resource "aws_apprunner_vpc_connector" "app" {
  vpc_connector_name = "${var.name}-connector"
  subnets = data.aws_subnets.default.ids
  security_groups = [aws_security_group.app.id]
}
resource "aws_apprunner_service" "app" {
  service_name = var.name
  source_configuration {
    auto_deployments_enabled = false
    image_repository {
      image_identifier = var.image_uri
      image_repository_type = "ECR"
      image_configuration {
        port = "8080"
        runtime_environment_variables = {
          "ASPNETCORE_ENVIRONMENT" = "Production"
          "ConnectionStrings__Inventory" = "Server=${aws_db_instance.sqlserver.address},1433;Database=master;User Id=${var.db_username};Password=${var.db_password};Encrypt=True;TrustServerCertificate=True"
        }
      }
    }
    authentication_configuration { access_role_arn = aws_iam_role.ecr.arn }
  }
  network_configuration { egress_configuration { egress_type = "VPC" vpc_connector_arn = aws_apprunner_vpc_connector.app.arn } }
  instance_configuration { cpu = "1 vCPU" memory = "2 GB" }
}
resource "aws_iam_role" "ecr" {
  name = "${var.name}-apprunner-ecr"
  assume_role_policy = jsonencode({Version="2012-10-17",Statement=[{Effect="Allow",Principal={Service="build.apprunner.amazonaws.com"},Action="sts:AssumeRole"}]})
}
resource "aws_iam_role_policy_attachment" "ecr" {
  role = aws_iam_role.ecr.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}
output "service_url" { value = aws_apprunner_service.app.service_url }
output "sql_server_endpoint" { value = aws_db_instance.sqlserver.address }
