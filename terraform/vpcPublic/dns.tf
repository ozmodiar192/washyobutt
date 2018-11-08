#Create wyb DNS zone, referencing previously created delegation set.
resource "aws_route53_zone" "wybPublic" {
  name = "washyobutt.com"
  delegation_set_id = "${var.delegationSet}"
}

resource "aws_route53_record" "quotes" {
  zone_id = "${aws_route53_zone.wybPublic.zone_id}"
  name    = "quotes.washyobutt.com"
  type    = "A"

  alias {
    name    =  "${aws_lb.wybNodeLB.dns_name}",
    zone_id = "${aws_lb.wybNodeLB.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "washyobutt" {
  zone_id = "${aws_route53_zone.wybPublic.zone_id}"
  name    = "washyobutt.com"
  type    = "A"

  alias { 
    name    =  "${aws_lb.wybWebLB.dns_name}",
    zone_id = "${aws_lb.wybWebLB.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "www" {
  zone_id = "${aws_route53_zone.wybPublic.zone_id}"
  name    = "www.washyobutt.com"
  type    = "A"

  alias { 
    name    =  "${aws_lb.wybWebLB.dns_name}",
    zone_id = "${aws_lb.wybWebLB.zone_id}"
    evaluate_target_health = true
  }
}

