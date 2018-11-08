#Create a security group to allow incoming ssh from my current external IP
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow inbound SSH traffic from my ip"
  vpc_id      = "${aws_vpc.wybPublic.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.icanhazip.body)}/32"]
  }

  tags {
    Name = "allow_ssh"
  }
}

# Output this security group so we can use it wherever.
output "sgAllowSSH" {
  value = "${aws_security_group.allow_ssh.id}"
}

# Allow website traffic
resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow website inbound traffic from all IPs"
  vpc_id      = "${aws_vpc.wybPublic.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443 
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] }

  tags {
    Name = "allow_web"
  }
}

# Output this security group so we can use it wherever.
output "sgAllowHTTP" {
  value = "${aws_security_group.allow_web.id}"
}

# Allow all outbound traffic
resource "aws_security_group" "allow_all_outbound" {
  name        = "allow_all_outbound"
  description = "Allow all outbound traffic"
  vpc_id      = "${aws_vpc.wybPublic.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "allow_outbound"
  }
}

# Output this security group so we can use it wherever.
output "sgAllowOutbound" {
  value = "${aws_security_group.allow_all_outbound.id}"
}

resource "aws_security_group" "allow_node" {
  name        = "allow_node"
  description = "Allow expressJS inbound traffic"
  vpc_id      = "${aws_vpc.wybPublic.id}"

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
    Name = "allow_node"
  }
}

# Output this security group so we can use it wherever.
output "sgAllowNode" {
  value = "${aws_security_group.allow_node.id}"
}

# Create keypair for provisioning the box
resource "aws_key_pair" "wybPublic" {
  key_name   = "wyb.pub"
  public_key = "${var.provisionerPublicKey}"
}

# Create IAM role for access to Dynamo from ECS
resource "aws_iam_role" "dynamoRORole" {
  name               = "dynamoRORole"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Policy for the Dynamo IAM Role
resource "aws_iam_role_policy" "dynamoROPolicy" {
  name   = "dynamoROPolicy"
  role   = "${aws_iam_role.dynamoRORole.id}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "application-autoscaling:DescribeScalableTargets",
                "application-autoscaling:DescribeScalingActivities",
                "application-autoscaling:DescribeScalingPolicies",
                "cloudwatch:DescribeAlarmHistory",
                "cloudwatch:DescribeAlarms",
                "cloudwatch:DescribeAlarmsForMetric",
                "cloudwatch:GetMetricStatistics",
                "cloudwatch:ListMetrics",
                "datapipeline:DescribeObjects",
                "datapipeline:DescribePipelines",
                "datapipeline:GetPipelineDefinition",
                "datapipeline:ListPipelines",
                "datapipeline:QueryObjects",
                "dynamodb:BatchGetItem",
                "dynamodb:DescribeTable",
                "dynamodb:GetItem",
                "dynamodb:ListTables",
                "dynamodb:Query",
                "dynamodb:Scan",
                "dynamodb:DescribeReservedCapacity",
                "dynamodb:DescribeReservedCapacityOfferings",
                "dynamodb:ListTagsOfResource",
                "dynamodb:DescribeTimeToLive",
                "dynamodb:DescribeLimits",
                "dynamodb:ListGlobalTables",
                "dynamodb:DescribeGlobalTable",
                "dynamodb:DescribeBackup",
                "dynamodb:ListBackups",
                "dynamodb:DescribeContinuousBackups",
                "dax:Describe*",
                "dax:List*",
                "dax:GetItem",
                "dax:BatchGetItem",
                "dax:Query",
                "dax:Scan",
                "ec2:DescribeVpcs",
                "ec2:DescribeSubnets",
                "ec2:DescribeSecurityGroups",
                "iam:GetRole",
                "iam:ListRoles",
                "sns:ListSubscriptionsByTopic",
                "sns:ListTopics",
                "lambda:ListFunctions",
                "lambda:ListEventSourceMappings",
                "lambda:GetFunctionConfiguration"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
EOF
}

# Output DynamoRole
output "rDynamoRO" {
  value = "${aws_iam_role.dynamoRORole.arn}"
}
