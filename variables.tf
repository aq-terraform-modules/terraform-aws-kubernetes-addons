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

variable "enable_aws_lb_controller" {
  description = "Enable AWS LB Controller or not"
  type        = bool
  default     = false
}

variable "aws_lb_controller_context" {
  description = "Set option for AWS LB Controller"
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

variable "jenkins_context" {
  description = "Set option for Jenkins"
  default     = {}
}

variable "account_id" {
  description = "Current AWS account ID to create IAM role"
}

variable "oidc_provider" {
  description = "EKS OIDC provider to create IAM role"
}