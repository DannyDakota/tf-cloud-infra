resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.application_name
}

resource "aws_ecs_service" "ecs_service" {
  name            = var.application_name
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = var.application_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [var.default_security_group_id]
    subnets          = var.private_subnet_ids
    assign_public_ip = true
  }
}

resource "aws_appautoscaling_target" "autoscaling_target" {
  service_namespace  = "ecs"
  min_capacity       = 1
  max_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
}


resource "aws_ecr_repository" "backend" {
  name = "backend-container-repository"
}

data "aws_caller_identity" "current" {}


resource "null_resource" "docker_packaging" {

  provisioner "local-exec" {
    command = <<EOF
	    aws ecr get-login-password --region ap-southeast-1 | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-southeast-1.amazonaws.com
	    docker build -t "${aws_ecr_repository.backend.repository_url}:latest" -f ./backend/Dockerfile .
	    docker push "${aws_ecr_repository.backend.repository_url}:latest"
	    EOF
  }


  triggers = {
    "run_at" = timestamp()
  }


  depends_on = [
    aws_ecr_repository.backend,
  ]
}

data "aws_iam_policy_document" "ecs" {
  version = "2012-10-17"
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}


resource "aws_iam_role" "ecs_execution" {
  name               = "iam_for_ecs"
  assume_role_policy = data.aws_iam_policy_document.ecs.json

  inline_policy {
    name = "ECRPermissions" # Give the policy a name

    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow",
          Action = [
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:BatchCheckLayerAvailability"
          ],
          Resource = "*"
        }
      ]
    })
  }
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "backend" {
  family                   = "backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  memory                   = 512
  cpu                      = 256
  execution_role_arn       = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([
    {
      name  = "backend-container"
      image = aws_ecr_repository.backend.repository_url

      log_configuration = {
        log_driver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/my-backend-logs"
          "awslogs-region"        = "ap-southeast-1"
          "awslogs-stream-prefix" = "my-backend-container"
        }
      }

      port_mappings = {
        container_port = 5000
        host_port      = 5000
      }
    }
  ])
  depends_on = [null_resource.docker_packaging]
}
