# Create an ecs cluster for our frontend services.
resource "aws_ecs_cluster" "wyb-frontend-cluster" {
  name        = "wyb-frontend-cluster"
}
