#Create wyb DNS zone, referencing previously created delegation set.
resource "aws_route53_zone" "wybPublic" {
  provider    = "aws.awsAssume"
  name = "washyobutt.com"
  delegation_set_id = "${var.delegationSet}"
}

# Create A record for my website
resource "aws_route53_record" "washyobutt" {
  provider    = "aws.awsAssume"
  zone_id = "${aws_route53_zone.wybPublic.zone_id}"
  name    = "washyobutt.com"
  type    = "A"
  ttl     = "30"

  records = [
    "${aws_instance.wybSingleton.public_ip}",
  ]
}

resource "aws_route53_record" "www" {
  provider    = "aws.awsAssume"
  zone_id = "${aws_route53_zone.wybPublic.zone_id}"
  name    = "www.washyobutt.com"
  type    = "A"
  ttl     = "30"

  records = [
    "${aws_instance.wybSingleton.public_ip}",
  ]
}
