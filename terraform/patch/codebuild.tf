data "template_file" "buildspecdev" {
  template = "${file("${path.module}/templates/buildspecdev.yml")}"
  vars = {
    topic_arn                   = "${aws_sns_topic.sns.arn}"
    updateGoldenImage           = "True"
  }
}


data "template_file" "buildspecprod" {
  template = "${file("${path.module}/templates/buildspecprod.yml")}"
  vars = {
    updateGoldenImage           = "True"
    topic_arn                   = "${aws_sns_topic.sns.arn}"
  }
}

resource "aws_codebuild_project" "codebuild" {
  name          = "Patch-${element(var.cbenv, 1)}"
  description   = "Prod Patch"
  build_timeout = "60"
  service_role  = "${aws_iam_role.codebuild_role.arn}"
  tags          = "${var.tags}"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "${var.computetype}"
    image                       = "${var.image_type}"
    type                        = "${var.containter_type}"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "environment"
      value = "${element(var.cbenv, 1)}"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "${data.template_file.buildspecprod.rendered}"
  }
}

resource "aws_codebuild_project" "codebuild1" {
  name          = "Patch-${element(var.cbenv, 2)}"
  description   = "Dev Patch"
  build_timeout = "60"
  service_role  = "${aws_iam_role.codebuild_role.arn}"
  tags          = "${var.tags}"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "${var.computetype}"
    image                       = "${var.image_type}"
    type                        = "${var.containter_type}"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "environment"
      value = "${element(var.cbenv, 2)}"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "${data.template_file.buildspecdev.rendered}"
  }
}
