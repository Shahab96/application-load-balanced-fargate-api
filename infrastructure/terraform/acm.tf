module "acm" {
  depends_on = [
    aws_route53_record.delegation
  ]

  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"

  domain_name = aws_route53_zone.this.name
  zone_id     = aws_route53_zone.this.zone_id

  wait_for_validation = true
}