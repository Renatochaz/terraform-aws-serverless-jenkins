provider "aws" {
  region = "us-east-1"
}

module "jenkins" {
  source = "../../"

  vpc_id                = "vpc-8282hd8sj2"
  public_subnets        = ["subnet-02396b30d428fe690", "subnet-07a209485112c354f"]
  private_subnets       = ["subnet-83hdsjs9jhe2", "subnet-dsh87273h287d82"]
  assign_public_ip      = false
  create_private_subnet = false

  alb_protocol        = "HTTPS"
  alb_policy_ssl      = "ELBSecurityPolicy-FS-1-2-Res-2019-08"
  alb_certificate_arn = var.certificate_arn

  route53_create_alias = true
  route53_zone_id      = "Z2ES7B9AZ6SHAE"
  route53_alias_name   = "jenkins"
  tags = {
    Module = "Serverless_Jenkins"
  }
}
