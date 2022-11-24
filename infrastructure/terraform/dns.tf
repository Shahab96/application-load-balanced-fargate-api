data "aws_route53_zone" "this" {
  name = "dev.dogar.dev"
}

resource "aws_route53_zone" "this" {
  name = "${local.project_prefix}.${data.aws_route53_zone.this.name}"
}

resource "aws_route53_record" "delegation" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = aws_route53_zone.this.name
  type    = "NS"
  ttl     = "60"
  records = aws_route53_zone.this.name_servers
}

resource "aws_route53_record" "this" {
  zone_id = aws_route53_zone.this.zone_id
  name    = aws_route53_zone.this.name
  type    = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}