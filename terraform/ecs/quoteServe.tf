# Create an ecs task for the nodejs servers
resource "aws_ecs_task_definition" "wybQSTask" {
  family                = "wybQSTask"
  network_mode          = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  container_definitions = "${file("tasks/quoteServe.json")}"
  cpu                   = "256"
  memory                = "512"
  execution_role_arn    = "${aws_iam_role.ecsTaskExecutionRole2.arn}"
  task_role_arn         = "${data.terraform_remote_state.vpc_public.rDynamoRO}"
}

# Create a service
resource "aws_ecs_service" "wybQSService" {
  name            = "wybQSService"
  cluster         = "${aws_ecs_cluster.wyb-frontend-cluster.id}"
  task_definition = "${aws_ecs_task_definition.wybQSTask.arn}"
  desired_count   = 1
  launch_type     = "FARGATE"
  depends_on      = ["aws_iam_role_policy.ecsTaskExecutionPolicy"]

  load_balancer {
    target_group_arn = "${data.terraform_remote_state.vpc_public.nodeTargetArn}"
    container_name   = "wybQSContainer"
    container_port   = 3000
  }

  lifecycle {
    ignore_changes = ["desired_count"]
  }

  network_configuration {
    security_groups  = ["${data.terraform_remote_state.vpc_public.sgAllowNode}", "${data.terraform_remote_state.vpc_public.sgAllowOutbound}"]
    subnets          = ["${data.terraform_remote_state.vpc_public.snMain}", "${data.terraform_remote_state.vpc_public.snSecondary}"]
    assign_public_ip = true
  }
}
