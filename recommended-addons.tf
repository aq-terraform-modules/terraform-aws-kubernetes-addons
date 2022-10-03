###########################################################
# INGRESS NGINX
###########################################################
resource "helm_release" "ingress_nginx" {
  count            = var.enable_ingress_nginx ? 1 : 0
  name             = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"

  values = [
    var.enable_cert_manager ? file("${path.module}/ingress-nginx/values-custom-with-certmanager.yaml") : file("${path.module}/ingress-nginx/values-custom.yaml")
  ]

  dynamic "set" {
    iterator = each_item
    for_each = var.enable_prometheus ? { "controller.metrics.enabled" : "true" } : {}

    content {
      name  = each_item.key
      value = each_item.value
    }
  }

  dynamic "set" {
    iterator = each_item
    for_each = var.enable_linkerd ? { "controller.podAnnotations.linkerd\\.io/inject" : "enabled" } : {}

    content {
      name  = each_item.key
      value = each_item.value
    }
  }

  dynamic "set" {
    iterator = each_item
    for_each = try(var.ingress_nginx_context, {})

    content {
      name  = each_item.key
      value = each_item.value
    }
  }

  depends_on = [
    helm_release.prometheus,
    helm_release.aws_loadbalancer_controller
  ]
}

###########################################################
# LOAD BALANCER CONTROLLER
###########################################################
resource "helm_release" "aws_loadbalancer_controller" {
  count            = var.enable_aws_lb_controller ? 1 : 0
  name             = "aws-load-balancer-controller"
  namespace        = "kube-system"
  create_namespace = true
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-load-balancer-controller"

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.aws_loadbalancer_controller[count.index].arn
  }

  dynamic "set" {
    iterator = each_item
    for_each = try(var.aws_lb_controller_context, {})

    content {
      name  = each_item.key
      value = each_item.value
    }
  }

  depends_on = [
    helm_release.prometheus
  ]
}

###########################################################
# EXTERNAL DNS
###########################################################
resource "helm_release" "external_dns" {
  count            = var.enable_external_dns ? 1 : 0
  name             = "external-dns"
  namespace        = "external-dns"
  create_namespace = true
  repository       = "https://kubernetes-sigs.github.io/external-dns"
  chart            = "external-dns"

  values = [
    file("${path.module}/external-dns/values-custom.yaml")
  ]

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.external_dns[count.index].arn
  }

  dynamic "set" {
    iterator = each_item
    for_each = try(var.external_dns_context, {})

    content {
      name  = each_item.key
      value = each_item.value
    }
  }

  depends_on = [
    helm_release.prometheus
  ]
}