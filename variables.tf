################################################################################
# Required
################################################################################
variable "vpc_id" {
  description = "ID of the VPC where the Jenkins will be deployed."
  type        = string
}

variable "jenkins_ecr_repository_name" {
  type        = string
  default     = "jenkins-controller"
  description = "Name for the Jenkins controller ECR repository."
}

variable "public_subnets" {
  type        = list(string)
  description = "A list of (preferable) different availability zone public subnets."
}

variable "private_subnets" {
  type        = list(string)
  description = "A list of (preferable) different availability zone private subnets. Use empty value if create_private_subnet is True."
}

variable "tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default     = {}
}

variable "name_prefix" {
  type        = string
  default     = "jenkins"
  description = "Prefix to be used on general resources."
}

################################################################################
# [Optional] Subnet Setup
################################################################################
variable "assign_public_ip" {
  type        = bool
  description = "Should public ip be assigned to Jenkins Controller and Agents. Use only if you need to deploy ECS on public subnets, instead of Private subnets with Nat Gateway."
  default     = false
}
variable "create_private_subnet" {
  type        = bool
  description = "Creates a private subnet with a NAT Gateway setup for ECS communication."
  default     = true
}

variable "private_subnet_cidr" {
  type        = string
  description = "CIDR block for the private subnet that will be setup if create_private_subnets is True."
  default     = ""
}

variable "natg_public_subnet" {
  description = "ID of a public subnet to route the NAT Gateway if create_private_subnets is True."
  type        = string
  default     = ""
}


################################################################################
# [Optional] Jenkins Controller Configuration
################################################################################
variable "jenkins_controller_port" {
  type        = number
  default     = 8080
  description = "Jenkins controller port number."
}

variable "jenkins_jnlp_port" {
  type        = number
  default     = 50000
  description = "Jenkins jnlp port number."
}

variable "jenkins_controller_cpu" {
  type        = number
  default     = 2048
  description = "Jenkins controller CPU."
}

variable "jenkins_controller_memory" {
  type        = number
  default     = 4096
  description = "Jenkins controller memory."
}

variable "jenkins_controller_task_log_retention_days" {
  type        = number
  default     = 7
  description = "Days to retain logs of Jenkins controller."
}
variable "alb_ingress_allow_cidrs" {
  type        = list(string)
  description = "A list of cidrs to allow inbound into Jenkins. Default to all."
  default     = ["0.0.0.0/0"]
}

################################################################################
# [Optional] Jenkins Agents Configuration
################################################################################
variable "jenkins_agents_provider" {
  type        = string
  default     = "FARGATE"
  description = "FARGATE or FARGATE_SPOT"
}

variable "jenkins_agents_cpu" {
  type        = number
  default     = 512
  description = "Jenkins agents CPU."
}

variable "jenkins_agents_memory_limit" {
  type        = number
  default     = 0
  description = "Hard limit on memory for jenkins agents. If 0, no memory limit is applied."
}

################################################################################
# [Optional] Application Load Balancer and Route53
################################################################################
variable "alb_protocol" {
  type        = string
  default     = "HTTP"
  description = "Protocol to use for the ALB."
}

variable "alb_policy_ssl" {
  type        = string
  default     = null
  description = "SSL policy name. Required if alb_protocol is HTTPS or TLS"
}

variable "alb_certificate_arn" {
  type        = string
  default     = null
  description = "ARN of the SSL certificate."
}

variable "route53_create_alias" {
  type        = string
  default     = false
  description = "should create alias from Route53 DNS."
}

variable "route53_zone_id" {
  type        = string
  default     = null
  description = "Route53 zone ID."
}

variable "route53_alias_name" {
  type        = string
  default     = "jenkins"
  description = "Route53 alias name."

}

################################################################################
# [Optional] EFS Configuration
################################################################################
variable "efs_enable_encryption" {
  type        = bool
  default     = true
  description = "Enable EFS encryption."
}

variable "efs_kms_key_arn" {
  type        = string
  default     = null // Defaults to aws/elasticfilesystem
  description = "KMS Key arn for the EFS."
}

variable "efs_performance_mode" {
  type        = string
  default     = "generalPurpose" // alternative is maxIO
  description = "EFS performance mode."
}

variable "efs_throughput_mode" {
  type        = string
  default     = "bursting" // alternative is provisioned
  description = "EFS throughput mode."
}

variable "efs_provisioned_throughput_in_mibps" {
  type        = number
  default     = null
  description = "EFS total provisioned throughput in mibs."
}

variable "efs_ia_lifecycle_policy" {
  type        = string
  default     = "AFTER_7_DAYS" // Valid values are AFTER_7_DAYS AFTER_14_DAYS AFTER_30_DAYS AFTER_60_DAYS AFTER_90_DAYS
  description = "EFS ia lifecycle policy."
}

variable "efs_access_point_uid" {
  type        = number
  description = "The uid number to associate with the EFS access point." // Jenkins 1000
  default     = 1000
}

variable "efs_access_point_gid" {
  type        = number
  description = "The gid number to associate with the EFS access point." // Jenkins 1000
  default     = 1000
}