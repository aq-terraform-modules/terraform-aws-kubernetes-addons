###########################################################
# EFS CSI Driver
###########################################################
module "efs_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  enabled    = var.enable_efs_csi_driver ? true : false
  attributes = ["efs-csi"]
  context    = var.base_label_context
}

module "efs_csi" {
  source     = "git::https://github.com/aq-terraform-modules/terraform-aws-efs.git?ref=master"
  create_efs = var.enable_efs_csi_driver ? true : false

  name            = module.efs_label.id
  encrypted       = true
  subnets         = module.base_network.private_subnets
  security_groups = [aws_security_group.efs.id]
  tags            = module.efs_label.tags
}