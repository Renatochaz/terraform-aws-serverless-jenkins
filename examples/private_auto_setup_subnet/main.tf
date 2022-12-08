provider "aws" {
  region = "us-east-1"
}

module "jenkins" {
  source = "../../"

  vpc_id         = "vpc-8282hd8sj2"
  public_subnets = ["subnet-02396b30d428fe690", "subnet-07a209485112c354f"]

  assign_public_ip      = false
  create_private_subnet = true
  private_subnets       = []
  private_subnet_cidr   = "172.31.112.0/24"
  natg_public_subnet    = "subnet-02396b30d428fe690" # Should use one of the public_subnets

}
