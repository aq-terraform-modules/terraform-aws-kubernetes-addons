module "kms_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  enabled    = var.enable_vault ? true : false
  attributes = ["kms"]
  context    = var.base_label_context
}

resource "aws_kms_key" "vault" {
  count                   = var.enable_vault ? 1 : 0
  description             = "AWS KMS Customer-managed key used for Vault auto-unseal and encryption"
  enable_key_rotation     = false
  is_enabled              = true
  key_usage               = "ENCRYPT_DECRYPT"

  tags = merge(
    { Name = "${module.kms_label.id}-vault-key" },
    tags = module.kms_label.tags
  )
}