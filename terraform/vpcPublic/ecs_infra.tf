# Create an ECR Repository to store our docker images.
resource "aws_ecr_repository" "wyb-repo" {
  name = "wyb-repo"
}
