###########################################################
# EFS CSI Driver
###########################################################
module "efs_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  enabled    = var.enable_efs_csi_driver ? true : false
  attributes = ["efs"]
  context    = var.base_label_context
}

module "efs_csi" {
  source     = "git::https://github.com/aq-terraform-modules/terraform-aws-efs.git?ref=master"
  create_efs = var.enable_efs_csi_driver ? true : false

  name            = "${module.efs_label.id}-csi"
  encrypted       = true
  subnets         = module.base_network.private_subnets
  security_groups = [aws_security_group.efs.id]
  tags            = module.efs_label.tags
}

###########################################################
# EFS Security Group
###########################################################
module "sg_label" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  attributes = ["sg"]
  context    = var.base_label_context
}
resource "aws_security_group" "efs" {
  name        = "${module.sg_label.id}-efs"
  description = "Allow inbound NFS traffic from private subnets of the VPC"
  vpc_id      = module.base_network.vpc_id

  ingress {
    description = "Allow NFS 2049/tcp"
    cidr_blocks = module.base_network.private_subnets_cidr_blocks
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
  }

  tags = module.sg_label.tags
}