[![](https://img.shields.io/github/license/Renatochaz/terraform-aws-serverless-jenkins)](https://github.com/Renatochaz/terraform-aws-serverless-jenkins)
[![](https://img.shields.io/github/issues/Renatochaz/terraform-aws-serverless-jenkins)](https://github.com/Renatochaz/terraform-aws-serverless-jenkins)
[![](https://img.shields.io/github/issues-closed/Renatochaz/terraform-aws-serverless-jenkins)](https://github.com/Renatochaz/terraform-aws-serverless-jenkins)


# Serverless Jenkins Terraform Module for AWS #

Terraform module to deploy a Serverless Jenkins service on AWS, providing high availability and scalability.

This module aims to abstract the complexity of desigin a reliable serverless Jenkins architecture, providing a easy and fast setup to a working jenkins capable of serving multiples teams.

*The bases of this module builds and improves on the work of AWS Authors who posted a sample of this architecture on the AWS official blog.*


## Architecture
![Architecture](https://raw.githubusercontent.com/Renatochaz/terraform-aws-serverless-jenkins/main/static/diagram.png)

## Prerequisites
The following are required to deploy this Terraform module

1. Terraform 0.14+
2. Docker 19+
3. Password for Jenkins must be stored in SSM Parameter store. This parameter must be of type `SecureString` and have the name `jenkins-admin`. Username is `admin`.

## Features
- Full configured Jenkins Controller on AWS Fargate with template for builds on Fargate Jenkins Agents.
- Pre-configured Jenkins Agents that can be provisioned with FARGATE or FARGATE_SPOT for cheaper pricing.
- Builds ECR Private Registry for builded Jenkins images.
- EFS as persistent layer for Jenkins Controller data with KMS encryption;
- Best practices on SG configuration for internal communication and temporary assumed roles with AWS STS. 
- Builds a application load balancer with HTTP or HTTPS if provided with Route53 and AWS Certificate.
- Single private subnet setup with configured NAT Gateway.

## Usage

### Complete setup for production environments

```
module "jenkins" {
  source = "Renatochaz/serverless-jenkins/aws"

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

```

### Auto generated private subnet

If you want the private subnet and connectivity setup by the module, set the `create_private_subnet` to true, and use one of the `public_subnets` ID's for the `natg_public_subnet` wich will route the private subnet traffic through the NAT Gateway.

```
module "jenkins" {
  source = "Renatochaz/serverless-jenkins/aws"

  vpc_id         = "vpc-8282hd8sj2"
  public_subnets = ["subnet-02396b30d428fe690", "subnet-07a209485112c354f"]

  assign_public_ip      = false
  create_private_subnet = true
  private_subnets       = []
  private_subnet_cidr   = "172.31.112.0/24"
  natg_public_subnet    = "subnet-02396b30d428fe690"

}

```

### Basic deploy in public subnets only

If you want a fast and cheap environment, probably for MOC/POC's or even for studying and exploring Jenkins, use only public subnets ID's to the `private_subnets` input and set the `jenkins_agents_provider` to `FARGATE_SPOT` to ensure the minimal pricing for this module. 

Please note that this means the environment is very vulnerable to attacks, and shoud not be used on production.

```
module "jenkins" {
  source = "Renatochaz/serverless-jenkins/aws"

  vpc_id                = "vpc-8282hd8sj2"
  public_subnets        = ["subnet-02396b30d428fe690", "subnet-07a209485112c354f"]
  private_subnets       = ["subnet-02396b30d428fe690"]
  create_private_subnet = false
  assign_public_ip      = true
  jenkins_agents_provider = "FARGATE_SPOT"

}

```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.40 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.40 |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |
| <a name="provider_template"></a> [template](#provider\_template) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ecr"></a> [ecr](#module\_ecr) | terraform-aws-modules/ecr/aws | 1.5.1 |
| <a name="module_private_subnet"></a> [private\_subnet](#module\_private\_subnet) | ./modules/private_subnet | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.jenkins_controller_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_ecs_cluster.jenkins_agents](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_ecs_cluster.jenkins_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_ecs_cluster_capacity_providers.jenkins_agents_provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster_capacity_providers) | resource |
| [aws_ecs_cluster_capacity_providers.jenkins_controller_provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster_capacity_providers) | resource |
| [aws_ecs_service.jenkins_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.jenkins_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_efs_access_point.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_access_point) | resource |
| [aws_efs_file_system.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_file_system) | resource |
| [aws_efs_file_system_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_file_system_policy) | resource |
| [aws_efs_mount_target.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_mount_target) | resource |
| [aws_iam_policy.ecs_execution_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.jenkins_controller_task_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.ecs_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.jenkins_controller_task_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.ecs_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.jenkins_controller_task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_kms_key.cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_lb.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_target_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_security_group.alb_security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.efs_security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.jenkins_controller_security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_service_discovery_private_dns_namespace.controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_private_dns_namespace) | resource |
| [aws_service_discovery_service.controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_service) | resource |
| [null_resource.build_docker_image](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.push_docker_image](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.render_template](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_ecr_authorization_token.token](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ecr_authorization_token) | data source |
| [aws_iam_policy_document.cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ecs_assume_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ecs_execution_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.efs_resource_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.jenkins_controller_task_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_vpc.target_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |
| [template_file.jenkins_configuration_def](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alb_certificate_arn"></a> [alb\_certificate\_arn](#input\_alb\_certificate\_arn) | ARN of the SSL certificate. | `string` | `null` | no |
| <a name="input_alb_ingress_allow_cidrs"></a> [alb\_ingress\_allow\_cidrs](#input\_alb\_ingress\_allow\_cidrs) | A list of cidrs to allow inbound into Jenkins. Default to all. | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| <a name="input_alb_policy_ssl"></a> [alb\_policy\_ssl](#input\_alb\_policy\_ssl) | SSL policy name. Required if alb\_protocol is HTTPS or TLS | `string` | `null` | no |
| <a name="input_alb_protocol"></a> [alb\_protocol](#input\_alb\_protocol) | Protocol to use for the ALB. | `string` | `"HTTP"` | no |
| <a name="input_assign_public_ip"></a> [assign\_public\_ip](#input\_assign\_public\_ip) | Should public ip be assigned to Jenkins Controller and Agents. Use only if you need to deploy ECS on public subnets, instead of Private subnets with Nat Gateway. | `bool` | `false` | no |
| <a name="input_create_private_subnet"></a> [create\_private\_subnet](#input\_create\_private\_subnet) | Creates a private subnet with a NAT Gateway setup for ECS communication. | `bool` | `true` | no |
| <a name="input_efs_access_point_gid"></a> [efs\_access\_point\_gid](#input\_efs\_access\_point\_gid) | The gid number to associate with the EFS access point. | `number` | `1000` | no |
| <a name="input_efs_access_point_uid"></a> [efs\_access\_point\_uid](#input\_efs\_access\_point\_uid) | The uid number to associate with the EFS access point. | `number` | `1000` | no |
| <a name="input_efs_enable_encryption"></a> [efs\_enable\_encryption](#input\_efs\_enable\_encryption) | Enable EFS encryption. | `bool` | `true` | no |
| <a name="input_efs_ia_lifecycle_policy"></a> [efs\_ia\_lifecycle\_policy](#input\_efs\_ia\_lifecycle\_policy) | EFS ia lifecycle policy. | `string` | `"AFTER_7_DAYS"` | no |
| <a name="input_efs_kms_key_arn"></a> [efs\_kms\_key\_arn](#input\_efs\_kms\_key\_arn) | KMS Key arn for the EFS. | `string` | `null` | no |
| <a name="input_efs_performance_mode"></a> [efs\_performance\_mode](#input\_efs\_performance\_mode) | EFS performance mode. | `string` | `"generalPurpose"` | no |
| <a name="input_efs_provisioned_throughput_in_mibps"></a> [efs\_provisioned\_throughput\_in\_mibps](#input\_efs\_provisioned\_throughput\_in\_mibps) | EFS total provisioned throughput in mibs. | `number` | `null` | no |
| <a name="input_efs_throughput_mode"></a> [efs\_throughput\_mode](#input\_efs\_throughput\_mode) | EFS throughput mode. | `string` | `"bursting"` | no |
| <a name="input_jenkins_agents_cpu"></a> [jenkins\_agents\_cpu](#input\_jenkins\_agents\_cpu) | Jenkins agents CPU. | `number` | `512` | no |
| <a name="input_jenkins_agents_memory_limit"></a> [jenkins\_agents\_memory\_limit](#input\_jenkins\_agents\_memory\_limit) | Hard limit on memory for jenkins agents. If 0, no memory limit is applied. | `number` | `0` | no |
| <a name="input_jenkins_agents_provider"></a> [jenkins\_agents\_provider](#input\_jenkins\_agents\_provider) | FARGATE or FARGATE\_SPOT | `string` | `"FARGATE"` | no |
| <a name="input_jenkins_controller_cpu"></a> [jenkins\_controller\_cpu](#input\_jenkins\_controller\_cpu) | Jenkins controller CPU. | `number` | `2048` | no |
| <a name="input_jenkins_controller_memory"></a> [jenkins\_controller\_memory](#input\_jenkins\_controller\_memory) | Jenkins controller memory. | `number` | `4096` | no |
| <a name="input_jenkins_controller_port"></a> [jenkins\_controller\_port](#input\_jenkins\_controller\_port) | Jenkins controller port number. | `number` | `8080` | no |
| <a name="input_jenkins_controller_task_log_retention_days"></a> [jenkins\_controller\_task\_log\_retention\_days](#input\_jenkins\_controller\_task\_log\_retention\_days) | Days to retain logs of Jenkins controller. | `number` | `7` | no |
| <a name="input_jenkins_ecr_repository_name"></a> [jenkins\_ecr\_repository\_name](#input\_jenkins\_ecr\_repository\_name) | Name for the Jenkins controller ECR repository. | `string` | `"jenkins-controller"` | no |
| <a name="input_jenkins_jnlp_port"></a> [jenkins\_jnlp\_port](#input\_jenkins\_jnlp\_port) | Jenkins jnlp port number. | `number` | `50000` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix to be used on general resources. | `string` | `"jenkins"` | no |
| <a name="input_natg_public_subnet"></a> [natg\_public\_subnet](#input\_natg\_public\_subnet) | ID of a public subnet to route the NAT Gateway if create\_private\_subnets is True. | `string` | `""` | no |
| <a name="input_private_subnet_cidr"></a> [private\_subnet\_cidr](#input\_private\_subnet\_cidr) | CIDR block for the private subnet that will be setup if create\_private\_subnets is True. | `string` | `""` | no |
| <a name="input_private_subnets"></a> [private\_subnets](#input\_private\_subnets) | A list of (preferable) different availability zone private subnets. Use empty value if create\_private\_subnet is True. | `list(string)` | n/a | yes |
| <a name="input_public_subnets"></a> [public\_subnets](#input\_public\_subnets) | A list of (preferable) different availability zone public subnets. | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources. | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC where the Jenkins will be deployed. | `string` | n/a | yes |
| <a name="input_route53_alias_name"></a> [route53\_alias\_name](#input\_route53\_alias\_name) | Route53 alias name. | `string` | `"jenkins"` | no |
| <a name="input_route53_create_alias"></a> [route53\_create\_alias](#input\_route53\_create\_alias) | should create alias from Route53 DNS. | `string` | `false` | no |
| <a name="input_route53_zone_id"></a> [route53\_zone\_id](#input\_route53\_zone\_id) | Route53 zone ID. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ecr_repository_arn"></a> [ecr\_repository\_arn](#output\_ecr\_repository\_arn) | ECR Repository ARN |
| <a name="output_efs_access_point_id"></a> [efs\_access\_point\_id](#output\_efs\_access\_point\_id) | EFS Access Point ID |
| <a name="output_efs_file_system_dns_name"></a> [efs\_file\_system\_dns\_name](#output\_efs\_file\_system\_dns\_name) | EFS file system DNS name |
| <a name="output_efs_file_system_id"></a> [efs\_file\_system\_id](#output\_efs\_file\_system\_id) | EFS file system ID |
| <a name="output_jenkins_alb_arn"></a> [jenkins\_alb\_arn](#output\_jenkins\_alb\_arn) | Jenkins Controller Load Balancer ARN |
| <a name="output_jenkins_alb_dns"></a> [jenkins\_alb\_dns](#output\_jenkins\_alb\_dns) | Jenkins Controller Load Balancer DNS name |
| <a name="output_repository_registry_id"></a> [repository\_registry\_id](#output\_repository\_registry\_id) | Registry ID where the ECR repository was created |
| <a name="output_repository_url"></a> [repository\_url](#output\_repository\_url) | ECR Repository URL |

