variable "base_label_context" {
  description = "Base label context that will be used to create other resource"
  type        = any
}

variable "enable_argocd" {
  description = "Enable ArgoCD or not"
  type        = bool
  default     = false
}

variable "argocd_context" {
  description = "Set option for ArgoCD"
  default     = {}
}

variable "enable_snapscheduler" {
  description = "Enable SnapScheduler to scheduler the VolumeSnapshot or not"
  type        = bool
  default     = false
}

variable "enable_efs_csi_driver" {
  description = "Enable EFS CSI Driver or not"
  type        = bool
  default     = false
}

variable "efs_csi_driver_context" {
  description = "Set option for EFS CSI Driver"
  default     = {}
}

variable "efs_network_properties" {
  description = "Network option for EFS"
  type        = any
}

variable "enable_aws_lb_controller" {
  description = "Enable AWS LB Controller or not"
  type        = bool
  default     = false
}

variable "aws_lb_controller_context" {
  description = "Set option for AWS LB Controller"
  default     = {}
}

variable "enable_prometheus" {
  description = "Enable Prometheus stack or not"
  type        = bool
  default     = false
}

variable "prometheus_context" {
  description = "Set option for prometheus"
  default     = {}
}


variable "enable_ingress_nginx" {
  description = "Enable Ingress Nginx or not"
  type        = bool
  default     = false
}

variable "ingress_nginx_context" {
  description = "Set option for Ingress Nginx"
  default     = {}
}

variable "enable_cert_manager" {
  description = "Enable Cert Manager or not"
  type        = bool
  default     = false
}

variable "cert_manager_context" {
  description = "Set option for Cert Manager"
  default     = {}
}

variable "enable_external_dns" {
  description = "Enable External DNS or not"
  type        = bool
  default     = false
}

variable "external_dns_context" {
  description = "Set option for External DNS"
  default     = {}
}

variable "enable_jenkins" {
  description = "Enable Jenkins or not"
  type        = bool
  default     = false
}

variable "jenkins_chart_version" {
  description = "Specify chart version for Jenkins chart"
  default     = ""
}

variable "jenkins_context" {
  description = "Set option for Jenkins"
  default     = {}
}

variable "enable_velero" {
  description = "Enable Velero service or not"
  type        = bool
  default     = false
}

variable "velero_context" {
  description = "Set option for Velero"
  default     = {}
}

variable "enable_keda" {
  description = "Enable Keda service or not"
  type        = bool
  default     = false
}

variable "keda_context" {
  description = "Set option for Keda"
  default     = {}
}

variable "enable_linkerd" {
  description = "Enable Linkerd service or not"
  type        = bool
  default     = false
}

variable "linkerd_context" {
  description = "Set context option for Linkerd"
  default     = {}
}

variable "linkerd_viz_context" {
  description = "Set context option for Linkerd-viz"
  default     = {}
}

variable "enable_vault" {
  description = "Enable Vault service or not"
  type        = bool
  default     = false
}

variable "vault_context" {
  description = "Set context option for Vault"
  default     = {}
}

variable "enable_secret_csi" {
  description = "Enable Secret CSI Driver service or not"
  type        = bool
  default     = false
}

variable "oidc_provider" {
  description = "EKS OIDC provider to create IAM role"
}