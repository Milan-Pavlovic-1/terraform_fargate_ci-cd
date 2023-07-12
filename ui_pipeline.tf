################

resource "aws_codestarconnections_connection" "example" {
  name          = "demo_connection_tf______"
  provider_type = "GitHub"
}

# make codepipeline
resource "aws_codepipeline" "example" {
  name     = "my-codepipeline_____"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.demos3.bucket
    type     = "S3"
  }

  # source stage
  stage {
    name = "Source"


    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.example.arn
        FullRepositoryId = "${var.github_repo_owner}/${var.github_repo_name}"
        BranchName       = var.github_branch
        #PollForSourceChanges = "true"
      }
    }
  }

  # build stage
  stage {
    name = "Build"

    action {
      name             = "BuildAction"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build"]

      configuration = {
        ProjectName = aws_codebuild_project.build.name
      }
    }
  }

  # deploy stage
  stage {
    name = "Deploy"

    action {
      name            = "DeployAction"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["build"]


      role_arn = aws_iam_role.codedeploy_role.arn
      configuration = {
        ClusterName = aws_ecs_cluster.my_cluster.name
        ServiceName = aws_ecs_service.my_service.name
      }
    }
  }
}

# codebuild project
resource "aws_codebuild_project" "build" {
  name         = "my-codebuild-project___"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:5.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true ## up until here was before
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml" # Update with your buildspec file name
  }
}