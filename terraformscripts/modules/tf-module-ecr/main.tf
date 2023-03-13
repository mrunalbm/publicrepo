resource "aws_ecr_repository" "this" {
  count = "${length(var.ecr_repos)}"
  name = "${element(var.ecr_repos, count.index)}"
}

resource "aws_ecr_repository_policy" "full_policy" {
  count = "${var.create_ecr_full_policy ? length(var.ecr_repos) : 0}"

  repository = "${element(aws_ecr_repository.this.*.name, count.index)}"

  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "ECRPolicy",
            "Effect": "Allow",
            "Principal": {
                "AWS": ${jsonencode(var.accounts_ids)}
            },
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:DescribeRepositories",
                "ecr:GetRepositoryPolicy",
                "ecr:ListImages",
                "ecr:DeleteRepository",
                "ecr:BatchDeleteImage",
                "ecr:SetRepositoryPolicy",
                "ecr:DeleteRepositoryPolicy"
            ]
        }
    ]
}
EOF
}

resource "aws_ecr_repository_policy" "pull_policy" {
  count = "${var.create_ecr_pull_policy ? length(var.ecr_repos) : 0}"

  repository = "${element(aws_ecr_repository.this.*.name, count.index)}"

  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "ECRPullPolicy",
            "Effect": "Allow",
            "Principal": {
                "AWS": ${jsonencode(var.accounts_ids)}
            },
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability"
            ]
        }
    ]
}
EOF
}

resource "aws_ecr_lifecycle_policy" "this" {
  count = "${var.enable_lifecycle_policy ? length(var.ecr_repos) : 0}"

  repository = "${element(aws_ecr_repository.this.*.name, count.index)}"

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep last ${var.number_of_images} images",
            "selection": {
                "tagStatus": "tagged",
                "tagPrefixList": ["${var.image_tag_prefix}"],
                "countType": "imageCountMoreThan",
                "countNumber": ${var.number_of_images}
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}
