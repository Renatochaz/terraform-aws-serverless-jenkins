output "jenkins_alb_dns" {
  value       = aws_lb.this.dns_name
  description = "Jenkins Controller Load Balancer DNS name"
}

output "jenkins_alb_arn" {
  description = "Jenkins Controller Load Balancer ARN"
  value       = aws_lb.this.arn
}

output "efs_file_system_id" {
  value       = aws_efs_file_system.this.id
  description = "EFS file system ID"
}

output "efs_file_system_dns_name" {
  value       = aws_efs_file_system.this.dns_name
  description = "EFS file system DNS name"
}

output "efs_access_point_id" {
  value       = aws_efs_access_point.this.id
  description = "EFS Access Point ID"
}

output "ecr_repository_arn" {
  description = "ECR Repository ARN"
  value       = module.ecr.repository_arn
}

output "repository_registry_id" {
  description = "Registry ID where the ECR repository was created"
  value       = module.ecr.repository_registry_id
}

output "repository_url" {
  description = "ECR Repository URL"
  value       = module.ecr.repository_url
}