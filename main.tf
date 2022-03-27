data "aws_partition" "current" {}
data "aws_region" "current" {}

data "aws_subnet_ids" "private" {
  vpc_id = var.vpc_id

  tags = {
    Name = "*private*"
  }
}

resource "random_id" "index" {
  byte_length = 2
}

locals {
  subnet_ids              = tolist(data.aws_subnet_ids.private.ids)
  subnet_ids_random_index = random_id.index.dec % length(data.aws_subnet_ids.private.ids)
  subnet_id               = local.subnet_ids[local.subnet_ids_random_index]
}

data "local_file" "build_file" {
  filename = "${path.module}/build.yml"
}

data "local_file" "test_file" {
  filename = "${path.module}/test.yml"
}

resource "aws_imagebuilder_component" "build_component" {
  name = "neo4j_build"
  version = var.build_component_version
  data                  = data.local_file.build_file.content
  platform              = "Linux"
  supported_os_versions = ["Amazon Linux 2"]
}

resource "aws_imagebuilder_component" "test_component" {
  name = "neo4j_test"
  version = var.test_component_version
  data                  = data.local_file.test_file.content
  platform              = "Linux"
  supported_os_versions = ["Amazon Linux 2"]
}

resource "aws_imagebuilder_infrastructure_configuration" "configuration" {
  name                          = "neo4j_database_infrastructure_configuration"
  instance_types                = var.instance_types
  key_pair                      = var.key_pair
  subnet_id                     = local.subnet_id
  terminate_instance_on_failure = true
}

resource "aws_imagebuilder_image_recipe" "recipe" {
  name         = "neo4j_image_recipe"
  parent_image = "arn:${data.aws_partition.current.partition}:imagebuilder:${data.aws_region.current.name}:aws:image/amazon-linux-2-x86/x.x.x"
  version      = var.recipe_version

  block_device_mapping {
    device_name = "/dev/xvda"

    ebs {
      delete_on_termination = true
      volume_size           = 8
      volume_type           = "gp2"
    }
  }

  component {
    component_arn = aws_imagebuilder_component.build_component.arn
  }
  component {
    component_arn = aws_imagebuilder_component.test_component.arn
  }
}
