# Serverless Jenkins exemple with self managed setup for subnets

Configuration in this directory create a serverless Jenkins controller in Fargate, and it's agents in another Fargate cluster for build self-service.

The configuration shown here only deploy the serverless Jenkins, and assume you configured the private and public subnets correctly, with your own architecture for external communication of the private subnets (NAT Gateway/AWS Endpoints).

This is the most recommended approach production environments, especially if multiple AZ public/subnets are specified in the module, and if you provisioned a certificate to setup the HTTPS for ALB.

Note that this example may create resources which cost money. Run `terraform destroy` when you don't need these resources.

## Prerequisites
The following are required to deploy this Terraform module

1. Terraform 0.14+
2. Docker 19+
3. Password for Jenkins must be stored in SSM Parameter store. This parameter must be of type `SecureString` and have the name `jenkins-admin`. Username is `admin`.

## Usage

To run this example you need to execute:

```bash
$ terraform init
$ terraform plan
$ terraform apply
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.4 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_jenkins"></a> [jenkins](#module\_jenkins) | ../../ | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_certificate_arn"></a> [certificate\_arn](#input\_certificate\_arn) | Certificate ARN for HTTPS | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ecr_repository_arn"></a> [ecr\_repository\_arn](#output\_ecr\_repository\_arn) | n/a |
| <a name="output_efs_access_point_id"></a> [efs\_access\_point\_id](#output\_efs\_access\_point\_id) | n/a |
| <a name="output_efs_file_system_dns_name"></a> [efs\_file\_system\_dns\_name](#output\_efs\_file\_system\_dns\_name) | n/a |
| <a name="output_efs_file_system_id"></a> [efs\_file\_system\_id](#output\_efs\_file\_system\_id) | n/a |
| <a name="output_jenkins_alb_arn"></a> [jenkins\_alb\_arn](#output\_jenkins\_alb\_arn) | n/a |
| <a name="output_jenkins_alb_dns"></a> [jenkins\_alb\_dns](#output\_jenkins\_alb\_dns) | n/a |
| <a name="output_repository_registry_id"></a> [repository\_registry\_id](#output\_repository\_registry\_id) | n/a |
| <a name="output_repository_url"></a> [repository\_url](#output\_repository\_url) | n/a |