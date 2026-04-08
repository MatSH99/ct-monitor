resource "aws_dynamodb_table" "cert_index" {
  name           = var.table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "domain_name"     # Partition Key
  range_key      = "cert_index"      # Sort Key

  attribute {
    name = "domain_name"
    type = "S"
  }

  attribute {
    name = "cert_index"
    type = "N"
  }

  attribute {
    name = "root_name"
    type = "S"
  }

  # Secondary index RootIndex
  global_secondary_index {
    name               = "RootIndex"
    hash_key           = "root_name"
    range_key	       = "cert_index"
    projection_type    = "ALL"
  }

  tags = {
    Name    = var.table_name
    Project = "ct-monitor"
  }
}

variable "table_name" {
  type = string
}

output "table_arn" {
  value = aws_dynamodb_table.cert_index.arn
}

output "table_name" {
  value = aws_dynamodb_table.cert_index.name
}
