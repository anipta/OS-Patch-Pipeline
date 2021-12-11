resource "aws_codepipeline" "codepipeline" {
  name     = "patch-pipeline"
  role_arn = "${aws_iam_role.codePipeline_role.arn}"
  tags     = "${var.tags}"

  artifact_store {
    location = "${aws_s3_bucket.patch_bucket-script.bucket}"
    type     = "S3"
  }

  # SourceCode
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["code"]

      configuration = {
        S3Bucket             = "${aws_s3_bucket.patch_bucket-script.id}"
        S3ObjectKey          = "patch.zip"
        PollForSourceChanges = "true"
      }
    }
  }

  # DEV
  stage {
    name = "Patch-dev"

    action {
      name            = "Patch-dev"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["code"]
      version         = "1"
      run_order       = 1

      configuration = {
        ProjectName = "Patch-dev"
      }
    }
  }

  #PROD
  stage {
    name = "Patch-prod"

    action {
      name       = "Approval"
      category   = "Approval"
      owner      = "AWS"
      provider   = "Manual"
      version    = "1"
      run_order  = 1

      configuration = {
        NotificationArn = "${aws_sns_topic.sns.arn}"
        CustomData = "VerifyDevPatch"
      }
    }

    action {
      name            = "Patch-prod"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["code"]
      version         = "1"
      run_order       = 2

      configuration = {
        ProjectName = "Patch-prod"
      }
    }
  }

}
