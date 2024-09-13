resource "aws_vpc" "one" {
  cidr_block       = var.cidr_block
  instance_tenancy = "default"
  enable_dns_hostnames = var.host_name

  tags = {
    Name = "SAM-vpc"
  }
}
# public subnet 1
resource "aws_subnet" "sub1" {
  vpc_id                  = aws_vpc.one.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1e"

  tags = {
    Name = "pub-sub-one"
  }
}
# public subnet 2
resource "aws_subnet" "sub2" {
  vpc_id                  = aws_vpc.one.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1f"

  tags = {
    Name = "pub-sub-two"
  }
}

# public subnet 3
resource "aws_subnet" "sub3" {
  vpc_id                  = aws_vpc.one.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1g"

  tags = {
    Name = "pub-sub-three"
  }
}


# IG
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.one.id

  tags = {
    Name = "Gateway"
  }
}

# Route table
resource "aws_route_table" "route1" {
  vpc_id                  = aws_vpc.one.id

  route {
    cidr_block            = "0.0.0.0/0"
    gateway_id            = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "route-table-one"
  }
}
# Association 
resource "aws_route_table_association" "a" {
  subnet_id                = aws_subnet.sub1.id
  route_table_id           = aws_route_table.route1.id
}

# Route table two
resource "aws_route_table" "route2" {
  vpc_id                  = aws_vpc.one.id

  route {
    cidr_block            = "0.0.0.0/0"
    gateway_id            = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "route-table-two"
  }
}
# Association 
resource "aws_route_table_association" "b" {
  subnet_id                = aws_subnet.sub2.id
  route_table_id           = aws_route_table.route2.id
}

# Route table three
resource "aws_route_table" "route3" {
  vpc_id                  = aws_vpc.one.id

  route {
    cidr_block            = "0.0.0.0/0"
    gateway_id            = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "route-table-three"
  }
}
# Association 
resource "aws_route_table_association" "c" {
  subnet_id                = aws_subnet.sub3.id
  route_table_id           = aws_route_table.route3.id
}


# security group
resource "aws_security_group" "public_sg" {
  name                      = "public-sg"
  description               = "Allow web and ssh traffic"
  vpc_id                    = aws_vpc.one.id

  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
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
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
}

# Instance profile
resource "aws_iam_instance_profile" "test_profile" {
  name = "test_profile"
  role = aws_iam_role.role.name
}

# IAM service role for 

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "role" {
  name               = "Developer-access"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "policy" {
  statement {
    effect    = "Allow"
    actions   = ["ec2:Describe*","s3:Describe"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "policy" {
  name        = "test-policy"
  description = "A test policy"
  policy      = data.aws_iam_policy_document.policy.json
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}


# Developer machine

resource "aws_instance" "Developer" {
  ami                           = var.ami_id
  instance_type                 = var.inst_type
  subnet_id                     = aws_subnet.sub1.id
  key_name                      = var.key
  associate_public_ip_address   = var.public_key
  security_groups               = [aws_security_group.public_sg.id]
  user_data                   = file("aws-cli.sh")
  tags = {
    Name = "Developer"
}
}

# Deploy machine

resource "aws_instance" "Deploy" {
  ami                           = var.ami_id
  instance_type                 = var.inst_type
  subnet_id                     = aws_subnet.sub2.id
  key_name                      = var.key
  associate_public_ip_address   = var.public_key
  security_groups               = [aws_security_group.public_sg.id]
  user_data                     = file("deploy.sh")
  iam_instance_profile          = aws_iam_instance_profile.test_profile.id
  tags = {
    Name = "Deploy"
}

}

# code Build

resource "aws_s3_bucket" "vinayaga" {
  bucket = "vinayga"
}

resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.vinayaga.id
  acl    = "private"
}

data "aws_iam_policy_document" "assume_role3" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "role3" {
  name               = "code-Build"
  assume_role_policy = data.aws_iam_policy_document.assume_role3.json
}

data "aws_iam_policy_document" "example" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVpcs",
    ]

    resources = ["*"]
  }
}


resource "aws_iam_role_policy" "example" {
  role   = aws_iam_role.role3.name
  policy = data.aws_iam_policy_document.example.json
}

resource "aws_codebuild_project" "codebuild" {
  name          = "vinayage"
  description   = "test_codebuild_project"
  build_timeout = 5
  service_role  = aws_iam_role.role3.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.vinayaga.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "SOME_KEY1"
      value = "SOME_VALUE1"
    }
  }
  logs_config {
    cloudwatch_logs {
      group_name  = "log-group"
      stream_name = "log-stream"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.vinayaga.id}/build-log"
    }
  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/Kabilan2370/Check.git"
    git_clone_depth = 1
  }

  tags = {
    Environment = "Test"
  }
}


# Code deploy

resource "aws_codedeploy_app" "code-deploy" {
  compute_platform = "Server"
  name             = "Mangatha"
}

resource "aws_codedeploy_deployment_group" "deployment_group" {
  app_name              = aws_codedeploy_app.code-deploy.name
  deployment_group_name = "group"
  service_role_arn      = aws_iam_role.role3.arn
  deployment_config_name = "CodeDeployDefault.AllAtOnce"
  #aws_instance            = aws_instance.Deploy.name
  #autoscaling_groups = [aws_autoscaling_group.autoscaling_group.name]
  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

   ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = "filtervalue"
    }

}
}

# code pipeline

resource "aws_codepipeline" "codepipeline" {
  name     = "Lenovo-project"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"

    # encryption_key {
    #   id   = data.aws_kms_alias.s3kmskey.arn
    #   type = "KMS"
    # }
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.medicate.arn
        FullRepositoryId = "Kabilan2370/Check"
        BranchName       = "main"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build-Plan"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      region           = "us-east-1"
      input_artifacts  = ["SourceArtifact"]
      #output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.codebuild.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      region          = "us-east-1"
      input_artifacts = ["BuildArtifact"]
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.codebuild.name
        ActionMode     = "REPLACE_ON_FAILURE"
        Capabilities   = "CAPABILITY_AUTO_EXPAND,CAPABILITY_IAM"
        OutputFileName = "CreateStackOutput.json"
        StackName      = "MyStack"
        TemplatePath   = "build_output::sam-templated.yaml"
      }
    }
  }
}

resource "aws_codestarconnections_connection" "medicate" {
  name          = "mediacate-to-github"
  provider_type = "GitHub"
}

resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "test-bucket"
}

resource "aws_s3_bucket_public_access_block" "codepipeline_bucket_pab" {
  bucket = aws_s3_bucket.codepipeline_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "assume_role2" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name               = "test-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role2.json
}

data "aws_iam_policy_document" "codepipeline_policy" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject",
    ]

    resources = [
      aws_s3_bucket.codepipeline_bucket.arn,
      "${aws_s3_bucket.codepipeline_bucket.arn}/*"
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["codestar-connections:UseConnection"]
    resources = [aws_codestarconnections_connection.medicate.arn]
  }

  statement {
    effect = "Allow"

    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "codepipeline_policy"
  role   = aws_iam_role.codepipeline_role.id
  policy = data.aws_iam_policy_document.codepipeline_policy.json
}




