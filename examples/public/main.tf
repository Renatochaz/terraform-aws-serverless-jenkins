provider "aws" {
  region = "us-east-1"
}

module "jenkins" {
  source = "../../"

  vpc_id                = "vpc-8282hd8sj2"
  public_subnets        = ["subnet-02396b30d428fe690", "subnet-07a209485112c354f"]
  private_subnets       = ["subnet-02396b30d428fe690"] # Passing public subnet as private, to enable internet connection without NAT/endpoints.
  create_private_subnet = false
  assign_public_ip      = true # Public subnet resources need public IP's to use Internet Gateway.
}
