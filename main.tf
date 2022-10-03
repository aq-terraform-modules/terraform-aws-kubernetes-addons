###########################################################
# ARGOCD
###########################################################
resource "helm_release" "argocd" {
  count            = var.enable_argocd ? 1 : 0
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version

  values = [
    file("${path.module}/argocd/values-custom.yaml")
  ]

  dynamic "set" {
    iterator = each_item
    for_each = try(var.argocd_context, {})

    content {
      name  = each_item.key
      value = each_item.value
    }
  }

  depends_on = [
    helm_release.prometheus,
    helm_release.ingress_nginx,
  ]
}

###########################################################
# PROMETHEUS
###########################################################
resource "helm_release" "prometheus" {
  count            = var.enable_prometheus ? 1 : 0
  name             = "prometheus"
  namespace        = "monitoring"
  create_namespace = true
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"

  values = [
    file("${path.module}/prometheus/values-custom.yaml")
  ]

  dynamic "set" {
    iterator = each_item
    for_each = var.enable_linkerd ? {} : {"prometheus.prometheusSpec.additionalScrapeConfigs": "[]"}

    content {
      name  = each_item.key
      value = each_item.value
    }
  }

  dynamic "set" {
    iterator = each_item
    for_each = try(var.prometheus_context, {})

    content {
      name  = each_item.key
      value = each_item.value
    }
  }
}

###########################################################
# SNAPSCHEDULER
###########################################################
resource "helm_release" "snapscheduler" {
  count            = var.enable_snapscheduler ? 1 : 0
  name             = "snapscheduler"
  namespace        = "snapscheduler"
  create_namespace = true
  repository       = "https://backube.github.io/helm-charts"
  chart            = "snapscheduler"

  values = [
    file("${path.module}/snapscheduler/values-custom.yaml")
  ]

  depends_on = [
    helm_release.prometheus
  ]
}

###########################################################
# EFS CSI Driver
###########################################################
resource "helm_release" "efs_csi_driver" {
  count            = var.enable_efs_csi_driver ? 1 : 0
  name             = "aws-efs-csi-driver"
  namespace        = "kube-system"
  create_namespace = true
  repository       = "https://kubernetes-sigs.github.io/aws-efs-csi-driver"
  chart            = "aws-efs-csi-driver"

  values = [
    file("${path.module}/efs-csi-driver/values-custom.yaml")
  ]

  set {
    name  = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.efs_csi_driver[count.index].arn
  }

  dynamic "set" {
    iterator = each_item
    for_each = try(var.efs_csi_driver_context, {})

    content {
      name  = each_item.key
      value = each_item.value
    }
  }

  depends_on = [
    helm_release.prometheus
  ]
}

resource "kubectl_manifest" "efs_storageclass" {
  count = var.enable_efs_csi_driver ? 1 : 0
  yaml_body = templatefile("${path.module}/efs-csi-driver/storageclass.yaml", {
    file_system_id = module.efs_csi.id
  })

  depends_on = [
    helm_release.efs_csi_driver
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
    for_each = var.enable_prometheus ? {"controller.metrics.enabled": "true"} : {}

    content {
      name  = each_item.key
      value = each_item.value
    }
  }

  dynamic "set" {
    iterator = each_item
    for_each = var.enable_linkerd ? {"controller.podAnnotations.linkerd\\.io/inject": "enabled"} : {}

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

  depends_on = [
    helm_release.prometheus
  ]
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

###########################################################
# JENKINS
###########################################################
resource "kubectl_manifest" "jenkins_namespace" {
  count     = var.enable_jenkins ? 1 : 0
  yaml_body = <<YAML
apiVersion: v1
kind: Namespace
metadata:
  name: jenkins
YAML
}

resource "kubectl_manifest" "jenkins_home_pvc" {
  count     = var.enable_jenkins ? 1 : 0
  yaml_body = file("${path.module}/jenkins/jenkins-home-pvc.yaml")

  depends_on = [
    kubectl_manifest.jenkins_namespace
  ]
}

resource "kubectl_manifest" "jenkins_home_snap_daily" {
  count     = var.enable_snapscheduler ? var.enable_jenkins ? 1 : 0 : 0
  yaml_body = file("${path.module}/jenkins/snap-daily.yaml")

  depends_on = [
    helm_release.snapscheduler,
    kubectl_manifest.jenkins_namespace
  ]
}

resource "helm_release" "jenkins" {
  count            = var.enable_jenkins ? 1 : 0
  name             = "jenkins"
  namespace        = "jenkins"
  create_namespace = true
  repository       = "https://charts.jenkins.io"
  chart            = "jenkins"
  version          = var.jenkins_chart_version

  values = [
    file("${path.module}/jenkins/values-custom.yaml")
  ]

  dynamic "set" {
    iterator = each_item
    for_each = var.enable_prometheus ? {"controller.prometheus.enabled": "true"} : {}

    content {
      name  = each_item.key
      value = each_item.value
    }
  }

  dynamic "set" {
    iterator = each_item
    for_each = try(var.jenkins_context, {})

    content {
      name  = each_item.key
      value = each_item.value
    }
  }

  depends_on = [
    helm_release.prometheus,
    helm_release.ingress_nginx,
    kubectl_manifest.jenkins_home_pvc
  ]
}

###########################################################
# VELERO
###########################################################
resource "helm_release" "velero" {
  count            = var.enable_velero ? 1 : 0
  name             = "velero"
  namespace        = "velero"
  create_namespace = true
  repository       = "https://vmware-tanzu.github.io/helm-charts"
  chart            = "velero"

  values = [
    file("${path.module}/velero/values-custom.yaml")
  ]

  set {
    name  = "serviceAccount.server.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.velero[count.index].arn
  }

  set {
    name  = "configuration.backupStorageLocation.bucket"
    value = module.s3_velero.s3_bucket_id
  }

  set {
    name  = "configuration.backupStorageLocation.config.region"
    value = module.s3_velero.s3_bucket_region
  }

  set {
    name  = "configuration.volumeSnapshotLocation.config.region"
    value = module.s3_velero.s3_bucket_region
  }

  dynamic "set" {
    iterator = each_item
    for_each = try(var.velero_context, {})

    content {
      name  = each_item.key
      value = each_item.value
    }
  }

  depends_on = [
    helm_release.prometheus,
  ]
}

###########################################################
# KEDA
###########################################################
resource "helm_release" "keda" {
  count            = var.enable_keda ? 1 : 0
  name             = "keda"
  namespace        = "keda"
  create_namespace = true
  repository       = "https://kedacore.github.io/charts"
  chart            = "keda"

  values = [
    file("${path.module}/keda/values-custom.yaml")
  ]

  dynamic "set" {
    iterator = each_item
    for_each = var.enable_prometheus ? {"prometheus.metricServer.enabled": "true", "prometheus.operator.enabled": "true"} : {}

    content {
      name  = each_item.key
      value = each_item.value
    }
  }

  dynamic "set" {
    iterator = each_item
    for_each = try(var.keda_context, {})

    content {
      name  = each_item.key
      value = each_item.value
    }
  }

  depends_on = [
    helm_release.prometheus,
  ]
}

###########################################################
# LINKERD
###########################################################

resource "helm_release" "linkerd" {
  count            = var.enable_linkerd ? 1 : 0
  name             = "linkerd2"
  repository       = "https://helm.linkerd.io/stable"
  chart            = "linkerd2"

  values = [
    file("${path.module}/linkerd/values-custom.yaml")
  ]

  dynamic "set" {
    iterator = each_item
    for_each = try(var.linkerd_context, {})

    content {
      name  = each_item.key
      value = each_item.value
    }
  }

  depends_on = [
    helm_release.prometheus,
  ]
}

resource "helm_release" "linkerd_viz" {
  count            = var.enable_linkerd ? 1 : 0
  name             = "linkerd-viz"
  repository       = "https://helm.linkerd.io/stable"
  chart            = "linkerd-viz"

  values = [
    file("${path.module}/linkerd/viz-values-custom.yaml")
  ]

  dynamic "set" {
    iterator = each_item
    for_each = try(var.linkerd_viz_context, {})

    content {
      name  = each_item.key
      value = each_item.value
    }
  }

  depends_on = [
    helm_release.prometheus,
    helm_release.linkerd,
  ]
}

###########################################################
# Vault
###########################################################
resource "helm_release" "vault" {
  count            = var.enable_vault ? 1 : 0
  name             = "vault"
  namespace        = "vault"
  create_namespace = true
  repository       = "https://helm.releases.hashicorp.com"
  chart            = "vault"

  values = [templatefile("${path.module}/vault/values-custom.yaml", {
    region     = local.region,
    kms_key_id = aws_kms_key.vault[0].key_id
  })]

  set {
    name  = "server.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.vault[count.index].arn
  }

  set {
    name  = "server.extraEnvironmentVars.AWS_DEFAULT_REGION"
    value = local.region
  }

  set {
    name  = "server.extraEnvironmentVars.AWS_REGION"
    value = local.region
  }

  dynamic "set" {
    iterator = each_item
    for_each = var.enable_secret_csi ? {"csi.enabled": "true"} : {}

    content {
      name  = each_item.key
      value = each_item.value
    }
  }

  dynamic "set" {
    iterator = each_item
    for_each = try(var.vault_context, {})

    content {
      name  = each_item.key
      value = each_item.value
    }
  }

  depends_on = [
    helm_release.prometheus,
    helm_release.ingress_nginx,
    aws_kms_key.vault
  ]
}

###########################################################
# Secret CSI
###########################################################
resource "helm_release" "secret_csi" {
  count            = var.enable_secret_csi ? 1 : 0
  name             = "secret-csi"
  namespace        = "kube-system"
  repository       = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart            = "secrets-store-csi-driver"

  set {
    name  = "syncSecret.enabled"
    value = true
  }
}
