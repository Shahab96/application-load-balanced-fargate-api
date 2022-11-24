resource "aws_ecr_repository" "this" {
  name         = local.project_prefix
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "null_resource" "this" {
  depends_on = [
    aws_ecr_repository.this
  ]

  provisioner "local-exec" {
    command = "../../deploy.sh ${local.project_prefix}"
  }
}