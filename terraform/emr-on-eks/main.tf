locals {
  region = "us-east-1"
  tags = {
    Owner       = "idata"
    Environment = "poc"
    Terraform   = "true"
  }
}

resource "aws_emrcontainers_virtual_cluster" "idata-poc" {
  container_provider {
    id   = data.terraform_remote_state.eks.outputs.cluster_id
    type = "EKS"

    info {
      eks_info {
        namespace = "spark"
      }
    }
  }

  name = var.environment_name
}

resource "aws_cloudwatch_log_group" "emr_eks" {
  name = "eks-emr-logs"

  tags = local.tags
}


resource "aws_iam_role" "EMRContainers_JobExecutionRole" {
  name = "EMRContainers-JobExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "elasticmapreduce.amazonaws.com"
        }
      },
    ]
  })

  tags = local.tags
}

data "aws_iam_policy_document" "EMR_Containers_Job_Execution" {
  statement {
    actions   = ["athena:*"]
    resources = ["arn:aws:athena:*:*:*/*"]
    effect    = "Allow"
  }

  statement {
    actions   = ["sns:*"]
    resources = ["*"]
    effect    = "Allow"
  }

  statement {
    actions   = ["dynamodb:*"]
    resources = ["*"]
    effect    = "Allow"
  }

  statement {
    actions   = ["glue:*"]
    resources = ["*"]
    effect    = "Allow"
  }

  statement {
    actions   = ["s3:*"]
    resources = ["*"]
    effect    = "Allow"
  }

  statement {
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = ["arn:aws:secretsmanager:*:*:secret:*"]
    effect    = "Allow"
  }

  statement {
    actions = ["logs:PutLogEvents",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
    "logs:DescribeLogStreams"]
    resources = ["arn:aws:logs:*:*:*"]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "EMR_Containers_Job_Execution" {
  name   = "EMR_Containers_Job_Execution"
  policy = data.aws_iam_policy_document.EMR_Containers_Job_Execution.json
}

resource "aws_iam_role_policy_attachment" "emr_containers_role_attach" {
  role       = aws_iam_role.EMRContainers_JobExecutionRole.name
  policy_arn = aws_iam_policy.EMR_Containers_Job_Execution.arn
}
