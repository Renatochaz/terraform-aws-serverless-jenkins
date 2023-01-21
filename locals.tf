locals {
  account_id      = data.aws_caller_identity.current.account_id
  region          = data.aws_region.current.name
  ecr_endpoint    = module.ecr.repository_url
  private_subnets = var.create_private_subnet == false ? var.private_subnets : [module.private_subnet[0].private_subnet_id]
}