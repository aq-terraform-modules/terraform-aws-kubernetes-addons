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
    name = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
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
}

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
    file("${path.module}/ingress-nginx/values-custom.yaml")
  ]

  dynamic "set" {
    iterator = each_item
    for_each = try(var.ingress_nginx_context, {})

    content {
      name  = each_item.key
      value = each_item.value
    }
  }
}

###########################################################
# CERT MANAGER
###########################################################
resource "helm_release" "cert_manager" {
  count            = var.enable_cert_manager ? 1 : 0
  name             = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"

  values = [
    file("${path.module}/cert-manager/values-custom.yaml")
  ]

  dynamic "set" {
    iterator = each_item
    for_each = try(var.cert_manager_context, {})

    content {
      name  = each_item.key
      value = each_item.value
    }
  }
}
resource "kubectl_manifest" "cluster_issuer" {
  count     = var.enable_cert_manager ? 1 : 0
  yaml_body = file("${path.module}/cert-manager/cluster-issuer.yaml")

  depends_on = [
    helm_release.cert_manager
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
    name = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
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
}

###########################################################
# JENKINS
###########################################################
resource "kubectl_manifest" "jenkins_namespace" {
    yaml_body = <<YAML
apiVersion: v1
kind: Namespace
metadata:
  name: jenkins
YAML
}

# resource "kubectl_manifest" "jenkins_home_pvc" {
#   yaml_body = file("${path.module}/jenkins/jenkins-home-pvc.yaml")

#   depends_on = [
#     kubectl_manifest.jenkins_namespace
#   ]
# }

resource "helm_release" "jenkins" {
  count            = var.enable_jenkins ? 1 : 0
  name             = "jenkins"
  namespace        = "jenkins"
  create_namespace = true
  repository       = "https://charts.jenkins.io"
  chart            = "jenkins"

  values = [
    file("${path.module}/jenkins/values-custom.yaml")
  ]

  dynamic "set" {
    iterator = each_item
    for_each = try(var.jenkins_context, {})

    content {
      name  = each_item.key
      value = each_item.value
    }
  }

  depends_on = [
    helm_release.ingress_nginx,
    kubectl_manifest.jenkins_home_pvc
  ]
}

resource "kubectl_manifest" "jenkins_snapshot" {
  yaml_body = file("${path.module}/jenkins/snapshot.yaml")

  depends_on = [
    kubectl_manifest.jenkins_home_pvc
  ]
}