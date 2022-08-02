###########################################################
# AWS LoadBalancer Controller IAM Role
###########################################################
resource "aws_iam_policy" "aws_loadbalancer_controller" {
  count  = var.enable_aws_lb_controller ? 1 : 0
  name   = "AWSLoadBalancerControllerIAMPolicy"
  policy = file("${path.module}/aws-loadbalancer-controller/policy.json")
}

resource "aws_iam_role" "aws_loadbalancer_controller" {
  count = var.enable_aws_lb_controller ? 1 : 0
  name  = "AWSLoadBalancerControllerIAMRole"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Principal : {
          Federated : "arn:aws:iam::${local.account_id}:oidc-provider/${var.oidc_provider}"
        },
        Action : "sts:AssumeRoleWithWebIdentity",
        Condition : {
          StringEquals : {
            "${var.oidc_provider}:aud" : "sts.amazonaws.com",
            "${var.oidc_provider}:sub" : "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "aws_loadbalancer_controller" {
  count      = var.enable_aws_lb_controller ? 1 : 0
  role       = aws_iam_role.aws_loadbalancer_controller[count.index].name
  policy_arn = aws_iam_policy.aws_loadbalancer_controller[count.index].arn
}

###########################################################
# External DNS IAM Role
###########################################################
resource "aws_iam_policy" "external_dns" {
  count  = var.enable_external_dns ? 1 : 0
  name   = "ExternalDNSIAMPolicy"
  policy = file("${path.module}/external-dns/policy.json")
}

resource "aws_iam_role" "external_dns" {
  count = var.enable_external_dns ? 1 : 0
  name  = "ExternalDNSIAMRole"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Principal : {
          Federated : "arn:aws:iam::${local.account_id}:oidc-provider/${var.oidc_provider}"
        },
        Action : "sts:AssumeRoleWithWebIdentity",
        Condition : {
          StringEquals : {
            "${var.oidc_provider}:aud" : "sts.amazonaws.com",
            "${var.oidc_provider}:sub" : "system:serviceaccount:external-dns:external-dns"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "external_dns" {
  count      = var.enable_external_dns ? 1 : 0
  role       = aws_iam_role.external_dns[count.index].name
  policy_arn = aws_iam_policy.external_dns[count.index].arn
}

###########################################################
# EFS CSI Driver IAM Role
###########################################################
resource "aws_iam_policy" "efs_csi_driver" {
  count  = var.enable_efs_csi_driver ? 1 : 0
  name   = "EFSCSIDriverIAMPolicy"
  policy = file("${path.module}/efs-csi-driver/policy.json")
}

resource "aws_iam_role" "efs_csi_driver" {
  count = var.enable_efs_csi_driver ? 1 : 0
  name  = "EFSCSIDriverIAMRole"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Principal : {
          Federated : "arn:aws:iam::${local.account_id}:oidc-provider/${var.oidc_provider}"
        },
        Action : "sts:AssumeRoleWithWebIdentity",
        Condition : {
          StringEquals : {
            "${var.oidc_provider}:sub" : "system:serviceaccount:kube-system:efs-csi-controller-sa"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "efs_csi_driver" {
  count      = var.enable_efs_csi_driver ? 1 : 0
  role       = aws_iam_role.efs_csi_driver[count.index].name
  policy_arn = aws_iam_policy.efs_csi_driver[count.index].arn
}

###########################################################
# EFS CSI Driver IAM Role
###########################################################
resource "aws_iam_policy" "velero" {
  count = var.enable_velero ? 1 : 0
  name  = "VeleroIAMPolicy"
  policy = templatefile("${path.module}/velero/policy.json", {
    s3_bucket_arn = module.s3_velero.s3_bucket_arn
  })
}

resource "aws_iam_role" "velero" {
  count = var.enable_velero ? 1 : 0
  name  = "VeleroIAMRole"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Principal : {
          Federated : "arn:aws:iam::${local.account_id}:oidc-provider/${var.oidc_provider}"
        },
        Action : "sts:AssumeRoleWithWebIdentity",
        Condition : {
          StringEquals : {
            "${var.oidc_provider}:aud" : "sts.amazonaws.com",
            "${var.oidc_provider}:sub" : "system:serviceaccount:velero:velero-sa"
          }
        }
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "velero" {
  count      = var.enable_velero ? 1 : 0
  role       = aws_iam_role.velero[count.index].name
  policy_arn = aws_iam_policy.velero[count.index].arn
}

###########################################################
# Vault IAM Role
###########################################################
resource "aws_iam_policy" "vault" {
  count  = var.enable_vault ? 1 : 0
  name   = "VaultIAMPolicy"
  policy = file("${path.module}/vault/policy.json")
}

resource "aws_iam_role" "vault" {
  count = var.enable_vault ? 1 : 0
  name  = "VaultIAMRole"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Principal : {
          Federated : "arn:aws:iam::${local.account_id}:oidc-provider/${var.oidc_provider}"
        },
        Action : "sts:AssumeRoleWithWebIdentity",
        Condition : {
          StringEquals : {
            "${var.oidc_provider}:aud": "sts.amazonaws.com",
            "${var.oidc_provider}:sub": "system:serviceaccount:vault:vault"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "vault" {
  count      = var.enable_vault ? 1 : 0
  role       = aws_iam_role.vault[count.index].name
  policy_arn = aws_iam_policy.vault[count.index].arn
}