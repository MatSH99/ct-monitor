terraform {
  source = "../modules"
}

include "root" {
  path = find_in_parent_folders()
}

dependency "tesseract" {
  config_path = "../../../tesseract/deployment/live/aws/test"
}

inputs = {
  table_name = "CertIndex-${dependency.tesseract.outputs.prefix}"
}
