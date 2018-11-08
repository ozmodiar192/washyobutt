resource "aws_lb" "wybWebLB" {
  name               = "wybWebLB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.allow_web.id}", "${aws_security_group.allow_all_outbound.id}"]
  subnets            = ["${aws_subnet.wybPublic_main.id}", "${aws_subnet.wybPublic_secondary.id}"]
  tags {
    Environment = "production"
  }
}

resource "aws_lb_target_group" "wybWebTargets" {
  name     = "wybWebTargets"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.wybPublic.id}"
  target_type = "ip"

  lifecycle {
    create_before_destroy = true
  }
}
 
resource "aws_lb_listener" "wybWebListener" {
  load_balancer_arn = "${aws_lb.wybWebLB.arn}"
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.wybWebTargets.arn}"
  }
}


output "webTargetArn" {
 value = "${aws_lb_target_group.wybWebTargets.arn}" 
}

