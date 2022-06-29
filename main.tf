###########################################################
# EXTERNAL SNAPSHOTTER
###########################################################

### Volume Snapshot Class
data "kubectl_file_documents" "volumesnapshotclasses" {
  content = file("${path.module}/ebs-csi-driver/snapshot.storage.k8s.io_volumesnapshotclasses.yaml")
}
resource "kubectl_manifest" "volumesnapshotclasses" {
  for_each  = data.kubectl_file_documents.volumesnapshotclasses.manifests
  yaml_body = each.value
}

### Volume Snapshot Contents
data "kubectl_file_documents" "volumesnapshotcontents" {
  content = file("${path.module}/ebs-csi-driver/snapshot.storage.k8s.io_volumesnapshotcontents.yaml")
}
resource "kubectl_manifest" "volumesnapshotcontents" {
  for_each  = data.kubectl_file_documents.volumesnapshotcontents.manifests
  yaml_body = each.value

  depends_on = [
    kubectl_manifest.volumesnapshotclasses
  ]
}

### Volume Snapshot
data "kubectl_file_documents" "volumesnapshots" {
  content = file("${path.module}/ebs-csi-driver/snapshot.storage.k8s.io_volumesnapshots.yaml")
}
resource "kubectl_manifest" "volumesnapshots" {
  for_each  = data.kubectl_file_documents.volumesnapshots.manifests
  yaml_body = each.value

  depends_on = [
    kubectl_manifest.volumesnapshotcontents
  ]
}

### RBAC for Snapshot Controller
data "kubectl_file_documents" "rbac_snapshot_controller" {
  content = file("${path.module}/ebs-csi-driver/rbac-snapshot-controller.yaml")
}
resource "kubectl_manifest" "rbac_snapshot_controller" {
  for_each  = data.kubectl_file_documents.rbac_snapshot_controller.manifests
  yaml_body = each.value

  depends_on = [
    kubectl_manifest.volumesnapshots
  ]
}

### Snapshot Controller
data "kubectl_file_documents" "setup_snapshot_controller" {
  content = file("${path.module}/ebs-csi-driver/setup-snapshot-controller.yaml")
}
resource "kubectl_manifest" "setup_snapshot_controller" {
  for_each  = data.kubectl_file_documents.setup_snapshot_controller.manifests
  yaml_body = each.value

  depends_on = [
    kubectl_manifest.rbac_snapshot_controller
  ]
}

### Storage Class
data "kubectl_file_documents" "ebs_storageclass" {
  content = file("${path.module}/ebs-csi-driver/storageclass.yaml")
}
resource "kubectl_manifest" "ebs_storageclass" {
  for_each  = data.kubectl_file_documents.ebs_storageclass.manifests
  yaml_body = each.value

  depends_on = [
    kubectl_manifest.setup_snapshot_controller
  ]
}

### Snapshot Storage Class
data "kubectl_file_documents" "snapshotclass" {
  content = file("${path.module}/ebs-csi-driver/snapshotclass.yaml")
}
resource "kubectl_manifest" "snapshotclass" {
  for_each  = data.kubectl_file_documents.snapshotclass.manifests
  yaml_body = each.value

  depends_on = [
    kubectl_manifest.setup_snapshot_controller
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
    helm_release.ingress_nginx
  ]
}

data "kubectl_file_documents" "jenkins_snapshot" {
  content = file("${path.module}/jenkins/snapshot.yaml")
}
resource "kubectl_manifest" "jenkins_snapshot" {
  for_each  = data.kubectl_file_documents.jenkins_snapshot.manifests
  yaml_body = each.value

  depends_on = [
    helm_release.jenkins,
    kubectl_manifest.snapshotclass
  ]
}