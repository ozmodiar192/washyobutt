# Create an ecs task for the web servers
resource "aws_ecs_task_definition" "wybWebTask" {
  family                = "wybWebTask"
  network_mode          = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  container_definitions = "${file("tasks/wybWeb.json")}"
  cpu                   = "256"
  memory                = "512"
  execution_role_arn    = "${aws_iam_role.ecsTaskExecutionRole2.arn}"
}

# Create a service
resource "aws_ecs_service" "wybWebService" {
  name            = "wybWebService"
  cluster         = "${aws_ecs_cluster.wyb-frontend-cluster.id}"
  task_definition = "${aws_ecs_task_definition.wybWebTask.arn}"
  desired_count   = 1
  launch_type     = "FARGATE"
  depends_on      = ["aws_iam_role_policy.ecsTaskExecutionPolicy"]

  load_balancer {
    target_group_arn = "${data.terraform_remote_state.vpc_public.webTargetArn}"
    container_name   = "wybwebContainer"
    container_port   = 80
  }

  lifecycle {
    ignore_changes = ["desired_count"]
  }

  network_configuration {
    security_groups  = ["${data.terraform_remote_state.vpc_public.sgAllowHTTP}", "${data.terraform_remote_state.vpc_public.sgAllowOutbound}"]
    subnets          = ["${data.terraform_remote_state.vpc_public.snMain}", "${data.terraform_remote_state.vpc_public.snSecondary}"]
    assign_public_ip = true
  }
}
