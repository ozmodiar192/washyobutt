#Create wyb DNS zone, referencing previously created delegation set.
resource "aws_route53_zone" "wybPublic" {
  name = "washyobutt.com"
  delegation_set_id = "N3DWCHIKKR8MP4"
}

# Create A records for my website
resource "aws_route53_record" "washyobutt" {
  zone_id = "${aws_route53_zone.wybPublic.zone_id}"
  name    = "washyobutt.com"
  type    = "A"
  ttl     = "30"

  records = [
    "${aws_instance.wybSingleton.public_ip}",
  ]
}

resource "aws_route53_record" "www" {
  zone_id = "${aws_route53_zone.wybPublic.zone_id}"
  name    = "www.washyobutt.com"
  type    = "A"
  ttl     = "30"

  records = [
    "${aws_instance.wybSingleton.public_ip}",
  ]
}
