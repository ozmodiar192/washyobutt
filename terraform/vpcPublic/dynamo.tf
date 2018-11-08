resource "aws_dynamodb_table" "quotes" {
  name           = "quotes"
  read_capacity  = 5
  write_capacity = 1
  hash_key       = "quoteID"

  attribute {
    name = "quoteID"
    type = "N"
  }
}
resource "aws_dynamodb_table" "quoteCount" {
  name           = "quoteCount"
  read_capacity  = 5
  write_capacity = 1
  hash_key       = "srcTable"

  attribute {
    name = "srcTable"
    type = "S"
  }
}
