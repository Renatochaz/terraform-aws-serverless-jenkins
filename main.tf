################################################################################
# Private Subnet Setup [Optional]
################################################################################
module "private_subnet" {
  count  = var.create_private_subnet ? 1 : 0
  source = "./modules/private_subnet"

  natg_public_subnet  = var.public_subnets[0]
  vpc_id              = var.vpc_id
  private_subnet_cidr = var.private_subnet_cidr

}

################################################################################
# ECR and Jenkins Image
################################################################################
module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "1.5.1"

  repository_name                 = var.jenkins_ecr_repository_name
  create_repository_policy        = false
  attach_repository_policy        = false
  repository_force_delete         = true
  repository_image_tag_mutability = "MUTABLE"
  repository_image_scan_on_push   = false

  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 30 images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["v"],
          countType     = "imageCountMoreThan",
          countNumber   = 30
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
}

data "template_file" "jenkins_configuration_def" {

  template = file("${path.module}/docker/files/jenkins.yaml.tfpl")

  vars = {
    ecs_cluster_fargate         = aws_ecs_cluster.jenkins_controller.arn
    ecs_cluster_fargate_agents  = aws_ecs_cluster.jenkins_agents.arn
    cluster_region              = local.region
    jenkins_cloud_map_name      = "controller.${var.name_prefix}"
    jenkins_controller_port     = var.jenkins_controller_port
    jnlp_port                   = var.jenkins_jnlp_port
    agent_security_groups       = aws_security_group.jenkins_controller_security_group.id
    execution_role_arn          = aws_iam_role.ecs_execution_role.arn
    subnets                     = join(",", local.private_subnets)
    jenkins_agents_cpu          = var.jenkins_agents_cpu
    jenkins_agents_memory_limit = var.jenkins_agents_memory_limit
    assign_public_ip            = var.assign_public_ip
  }
}

resource "null_resource" "render_template" {
  triggers = {
    always_run = timestamp()
  }

  depends_on = [data.template_file.jenkins_configuration_def]

  provisioner "local-exec" {
    command = <<EOF
tee ${path.module}/docker/files/jenkins.yaml <<ENDF
${data.template_file.jenkins_configuration_def.rendered}
EOF
  }
}

resource "null_resource" "build_docker_image" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<EOF
docker build -t ${local.ecr_endpoint}:latest ${path.module}/docker/
EOF
  }

  depends_on = [null_resource.render_template]
}

resource "null_resource" "push_docker_image" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<EOF
aws ecr get-login-password --region ${local.region} | docker login --username AWS --password-stdin ${local.ecr_endpoint} && \
docker push ${local.ecr_endpoint}:latest
EOF
  }

  depends_on = [null_resource.build_docker_image]
}

################################################################################
# EFS
################################################################################
resource "aws_efs_file_system" "this" {
  creation_token = "${var.name_prefix}-efs"

  encrypted                       = var.efs_enable_encryption
  kms_key_id                      = var.efs_kms_key_arn
  performance_mode                = var.efs_performance_mode
  throughput_mode                 = var.efs_throughput_mode
  provisioned_throughput_in_mibps = var.efs_provisioned_throughput_in_mibps

  lifecycle_policy {
    transition_to_ia = var.efs_ia_lifecycle_policy
  }

  tags = var.tags
}

resource "aws_efs_access_point" "this" {
  file_system_id = aws_efs_file_system.this.id

  posix_user {
    gid = 0
    uid = 0
  }

  root_directory {
    path = "/"
    creation_info {
      owner_gid   = var.efs_access_point_uid
      owner_uid   = var.efs_access_point_gid
      permissions = "755"
    }
  }

  tags = var.tags
}


resource "aws_efs_mount_target" "this" {
  count = length(local.private_subnets)

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = local.private_subnets[count.index]
  security_groups = [aws_security_group.efs_security_group.id]
}

################################################################################
# ECS
################################################################################
resource "aws_ecs_cluster" "jenkins_controller" {
  name = "${var.name_prefix}-controller"
  tags = var.tags
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster" "jenkins_agents" {
  name = "${var.name_prefix}-agents"
  tags = var.tags
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "jenkins_controller_provider" {
  cluster_name       = aws_ecs_cluster.jenkins_controller.name
  capacity_providers = ["FARGATE"]
  depends_on         = [aws_iam_role.ecs_execution_role]
}

resource "aws_ecs_cluster_capacity_providers" "jenkins_agents_provider" {
  cluster_name       = aws_ecs_cluster.jenkins_agents.name
  capacity_providers = [var.jenkins_agents_provider]
  depends_on         = [aws_iam_role.ecs_execution_role]
}

resource "aws_ecs_task_definition" "jenkins_controller" {
  family = var.name_prefix

  task_role_arn            = aws_iam_role.jenkins_controller_task_role.arn
  execution_role_arn       = aws_iam_role.jenkins_controller_task_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.jenkins_controller_cpu
  memory                   = var.jenkins_controller_memory
  container_definitions = templatefile(
    "${path.module}/templates/jenkins-controller.json.tfpl",
    {
      name                    = "${var.name_prefix}-controller"
      jenkins_controller_port = var.jenkins_controller_port
      jnlp_port               = var.jenkins_jnlp_port
      source_volume           = "${var.name_prefix}-efs"
      jenkins_home            = "/var/jenkins_home"
      container_image         = format("%s:latest", module.ecr.repository_url)
      region                  = local.region
      account_id              = local.account_id
      memory                  = var.jenkins_controller_memory
      cpu                     = var.jenkins_controller_cpu
      log_group               = aws_cloudwatch_log_group.jenkins_controller_log_group.name
    }
  )

  volume {
    name = "${var.name_prefix}-efs"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.this.id
      transit_encryption = "ENABLED"

      authorization_config {
        access_point_id = aws_efs_access_point.this.id
        iam             = "ENABLED"
      }
    }
  }

  tags = var.tags
}

resource "aws_kms_key" "cloudwatch" {
  description = "KMS for cloudwatch log group"
  policy      = data.aws_iam_policy_document.cloudwatch.json
}

resource "aws_cloudwatch_log_group" "jenkins_controller_log_group" {
  name              = var.name_prefix
  retention_in_days = var.jenkins_controller_task_log_retention_days
  kms_key_id        = aws_kms_key.cloudwatch.arn
  tags              = var.tags
}

resource "aws_ecs_service" "jenkins_controller" {
  name = "${var.name_prefix}-controller"

  task_definition  = aws_ecs_task_definition.jenkins_controller.arn
  cluster          = aws_ecs_cluster.jenkins_controller.id
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  // Assuming we cannot have more than one instance at a time. Ever. 
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0


  service_registries {
    registry_arn = aws_service_discovery_service.controller.arn
    port         = var.jenkins_jnlp_port
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = "${var.name_prefix}-controller"
    container_port   = var.jenkins_controller_port
  }

  network_configuration {
    subnets          = local.private_subnets
    security_groups  = [aws_security_group.jenkins_controller_security_group.id]
    assign_public_ip = var.assign_public_ip
  }

  depends_on = [aws_lb_listener.alb, null_resource.push_docker_image]
}


resource "aws_service_discovery_private_dns_namespace" "controller" {
  name        = var.name_prefix
  vpc         = var.vpc_id
  description = "Serverless Jenkins discovery managed zone."
}


resource "aws_service_discovery_service" "controller" {
  name = "controller"
  dns_config {
    namespace_id   = aws_service_discovery_private_dns_namespace.controller.id
    routing_policy = "MULTIVALUE"
    dns_records {
      ttl  = 10
      type = "A"
    }

    dns_records {
      ttl  = 10
      type = "SRV"
    }
  }
  health_check_custom_config {
    failure_threshold = 5
  }
}

################################################################################
# IAM
################################################################################
data "aws_iam_policy_document" "efs_resource_policy" {
  statement {
    effect = "Allow"
    actions = [
      "elasticfilesystem:ClientRootAccess",
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite"
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }

    resources = [
      "arn:aws:elasticfilesystem:${local.region}:${local.account_id}:file-system/${aws_efs_file_system.this.id}"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["true"]
    }
  }
}

resource "aws_efs_file_system_policy" "this" {
  file_system_id = aws_efs_file_system.this.id
  policy         = data.aws_iam_policy_document.efs_resource_policy.json
}

data "aws_iam_policy_document" "ecs_assume_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ecs_execution_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "ecs_execution_role" {
  name               = "${var.name_prefix}-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_policy.json
  tags               = var.tags
}

resource "aws_iam_policy" "ecs_execution_policy" {
  name   = "${var.name_prefix}-ecs-execution-policy"
  policy = data.aws_iam_policy_document.ecs_execution_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.ecs_execution_policy.arn
}

data "aws_iam_policy_document" "jenkins_controller_task_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ecs:ListContainerInstances"
    ]
    resources = [aws_ecs_cluster.jenkins_controller.arn, aws_ecs_cluster.jenkins_agents.arn]
  }
  statement {
    effect = "Allow"
    actions = [
      "ecs:RunTask"
    ]
    condition {
      test     = "ArnEquals"
      variable = "ecs:cluster"
      values = [
        aws_ecs_cluster.jenkins_controller.arn,
        aws_ecs_cluster.jenkins_agents.arn
      ]
    }
    resources = ["arn:aws:ecs:${local.region}:${local.account_id}:task-definition/*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "ecs:StopTask",
      "ecs:DescribeTasks"
    ]
    condition {
      test     = "ArnEquals"
      variable = "ecs:cluster"
      values = [
        aws_ecs_cluster.jenkins_controller.arn,
        aws_ecs_cluster.jenkins_agents.arn
      ]
    }
    resources = ["arn:aws:ecs:${local.region}:${local.account_id}:task/*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "ssm:PutParameter",
      "ssm:GetParameter",
      "ssm:GetParameters"
    ]
    resources = ["arn:aws:ssm:${local.region}:${local.account_id}:parameter/jenkins*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt"
    ]
    resources = ["arn:aws:kms:${local.region}:${local.account_id}:alias/aws/ssm"]
  }
  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = ["arn:aws:iam::${local.account_id}:role/*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["${aws_cloudwatch_log_group.jenkins_controller_log_group.arn}:*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "elasticfilesystem:ClientMount",
      "ecr:GetAuthorizationToken",
      "ecs:RegisterTaskDefinition",
      "ecs:ListClusters",
      "ecs:DescribeContainerInstances",
      "ecs:ListTaskDefinitions",
      "ecs:DescribeTaskDefinition",
      "ecs:DeregisterTaskDefinition"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "elasticfilesystem:ClientWrite",
      "elasticfilesystem:ClientRootAccess",
    ]
    resources = [
      aws_efs_file_system.this.arn,
    ]
  }
}

resource "aws_iam_policy" "jenkins_controller_task_policy" {
  name   = "${var.name_prefix}-controller-task-policy"
  policy = data.aws_iam_policy_document.jenkins_controller_task_policy.json
}

resource "aws_iam_role" "jenkins_controller_task_role" {
  name               = "${var.name_prefix}-controller-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_policy.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "jenkins_controller_task" {
  role       = aws_iam_role.jenkins_controller_task_role.name
  policy_arn = aws_iam_policy.jenkins_controller_task_policy.arn
}

data "aws_iam_policy_document" "cloudwatch" {
  policy_id = "key-policy-cloudwatch"
  statement {
    sid = "Enable IAM User Permissions"
    actions = [
      "kms:*",
    ]
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }
    resources = ["*"]
  }
  statement {
    sid = "AllowCloudWatchLogs"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["logs.${local.region}.amazonaws.com"]
    }
    resources = ["*"]
  }
}

################################################################################
# Security Groups
################################################################################
resource "aws_security_group" "efs_security_group" {
  name        = "${var.name_prefix}-efs"
  description = "${var.name_prefix} efs security group"
  vpc_id      = var.vpc_id


  ingress {
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins_controller_security_group.id]
    from_port       = 2049
    to_port         = 2049
  }
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_security_group" "jenkins_controller_security_group" {
  name        = "${var.name_prefix}-controller"
  description = "${var.name_prefix} controller security group"
  vpc_id      = var.vpc_id

  ingress {
    protocol        = "tcp"
    self            = true
    security_groups = [aws_security_group.alb_security_group.id]
    from_port       = var.jenkins_controller_port
    to_port         = var.jenkins_controller_port
    description     = "Communication channel to jenkins leader"
  }

  ingress {
    protocol        = "tcp"
    self            = true
    security_groups = [aws_security_group.alb_security_group.id]
    from_port       = var.jenkins_jnlp_port
    to_port         = var.jenkins_jnlp_port
    description     = "Communication channel to jenkins leader"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_security_group" "alb_security_group" {

  name        = "${var.name_prefix}-alb"
  description = "${var.name_prefix} alb security group"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = var.alb_ingress_allow_cidrs
    description = "HTTP Public access"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = var.alb_ingress_allow_cidrs
    description = "HTTPS Public access"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

################################################################################
# Load Balancer
################################################################################
resource "aws_lb" "this" {
  name               = replace("${var.name_prefix}-crtl-alb", "_", "-")
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_security_group.id]
  subnets            = var.public_subnets

  tags = var.tags
}

resource "aws_lb_target_group" "this" {
  name        = replace("${var.name_prefix}-crtl", "_", "-")
  port        = var.jenkins_controller_port
  protocol    = var.alb_protocol
  vpc_id      = var.vpc_id
  target_type = "ip"

  tags       = var.tags
  depends_on = [aws_lb.this]

  health_check {
    enabled             = true
    path                = "/login"
    interval            = "30"
    timeout             = "10"
    unhealthy_threshold = "10"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "alb" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = var.alb_protocol
  ssl_policy        = var.alb_policy_ssl
  certificate_arn   = var.alb_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_route53_record" "this" {
  count = var.route53_create_alias ? 1 : 0

  zone_id = var.route53_zone_id
  name    = var.route53_alias_name
  type    = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}