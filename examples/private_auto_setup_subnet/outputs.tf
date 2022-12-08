output "jenkins_alb_dns" {
  value = module.jenkins.jenkins_alb_dns
}

output "jenkins_alb_arn" {
  value = module.jenkins.jenkins_alb_arn
}

output "efs_file_system_id" {
  value = module.jenkins.efs_file_system_id
}

output "efs_file_system_dns_name" {
  value = module.jenkins.efs_file_system_dns_name
}

output "efs_access_point_id" {
  value = module.jenkins.efs_access_point_id
}

output "ecr_repository_arn" {
  value = module.jenkins.ecr_repository_arn
}
output "repository_registry_id" {
  value = module.jenkins.repository_registry_id
}

output "repository_url" {
  value = module.jenkins.repository_url
}