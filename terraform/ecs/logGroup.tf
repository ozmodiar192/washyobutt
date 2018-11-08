resource "aws_cloudwatch_log_group" "wybWebTask" {
  name = "/ecs/wybWebTask"

  tags {
    Environment = "production"
    Application = "web"
  }
}

resource "aws_cloudwatch_log_group" "wybQSTask" {
  name = "/ecs/wybQSTask"

  tags {
    Environment = "production"
    Application = "quoteServe"
  }
}
