variable "vpc_id" {
  type = string
  description = "The id of the VPC to be used for the image pipeline"
}

variable "build_component_version" {
  type = string
  description = "The version of the image build component of type 'build'"
}

variable "test_component_version" {
  type = string
  description = "The version of the image build component of type 'test'"
}

variable "recipe_version" {
  type = string
  description = "The version of the image recipe"
}
