###########################################################
# AWS LoadBalancer Controller IAM Role
###########################################################
resource "aws_iam_policy" "aws_loadbalancer_controller" {
  count  = var.enable_aws_lb_controller ? 1 : 0
  name   = "AWSLoadBalancerControllerIAMPolicy"
  policy = file("${path.module}/aws-loadbalancer-controller/policy.json")
}

resource "aws_iam_role" "aws_loadbalancer_controller" {
  count  = var.enable_aws_lb_controller ? 1 : 0
  name = "AWSLoadBalancerControllerIAMRole"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Principal : {
          Federated : "arn:aws:iam::${var.account_id}:oidc-provider/${var.oidc_provider}"
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
  count  = var.enable_aws_lb_controller ? 1 : 0
  role       = aws_iam_role.aws_loadbalancer_controller.name
  policy_arn = aws_iam_policy.aws_loadbalancer_controller.arn
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
  count  = var.enable_external_dns ? 1 : 0
  name = "ExternalDNSIAMRole"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Principal : {
          Federated : "arn:aws:iam::${var.account_id}:oidc-provider/${var.oidc_provider}"
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
  count  = var.enable_external_dns ? 1 : 0
  role       = aws_iam_role.external_dns.name
  policy_arn = aws_iam_policy.external_dns.arn
}