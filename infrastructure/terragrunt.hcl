# infrastructure/terragrunt.hcl
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "eu-west-1" 
}
EOF
}

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  backend "s3" {}
}
EOF
}

dependency "tesseract" {
  config_path = "../../tesseract/deployment/live/aws/test"
}

remote_state {
  backend = "s3"

  config = {
    region = "eu-west-1"
    bucket = "${dependency.tesseract.outputs.prefix_name}-${dependency.tesseract.outputs.base_name}-terraform-state"
    key    = "${path_relative_to_include()}/terraform.tfstate"
    s3_bucket_tags = {
      name = "terraform_state_storage"
    }
    use_lockfile = true
  }
}
