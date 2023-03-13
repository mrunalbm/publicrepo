output "ecr_repos_urls" {
  value = "${zipmap(var.ecr_repos, aws_ecr_repository.this.*.repository_url)}"
}
