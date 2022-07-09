###########################################################
# VELERO
###########################################################
module "s3_velero_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  enabled    = var.enable_velero ? true : false
  attributes = ["s3-velero"]
  context    = var.base_label_context
}

module "s3_velero" {
  source        = "terraform-aws-modules/s3-bucket/aws"
  version       = "3.3.0"
  create_bucket = enable_velero ? true : false

  bucket = module.s3_velero_label.id
  acl    = "private"

  versioning = {
    enabled = true
  }
}
