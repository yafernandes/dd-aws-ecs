data "aws_route53_zone" "pipsquack" {
  name = var.domain
}

resource "aws_route53_record" "app-java" {
  zone_id = data.aws_route53_zone.pipsquack.zone_id
  name    = "app.ecs"
  type    = "A"
  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = false
  }
}
