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

dependency "tesseract" {
  config_path = "../../tesseract/deployment/live/aws/test"
}

remote_state {
  backend = "s3"

  config = {
    region = "eu-west-1"
    bucket = "${local.prefix_name}-${local.base_name}-terraform-state"
    key    = "${path_relative_to_include()}/terraform.tfstate"
    s3_bucket_tags = {
      name = "terraform_state_storage"
    }
    use_lockfile = true
  }
}
