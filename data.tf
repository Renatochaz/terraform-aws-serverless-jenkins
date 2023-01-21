data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_ecr_authorization_token" "token" {}
data "aws_vpc" "target_vpc" {
  id = var.vpc_id
}