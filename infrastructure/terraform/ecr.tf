resource "aws_ecr_repository" "this" {
  name                 = local.project_prefix
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}