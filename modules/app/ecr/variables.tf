# ECR Module Variables

variable "applications" {
  description = "Map of applications with ECR configuration"
  type = map(object({
    ecr_repository_name = string
    app_path            = string
    image_version       = string
  }))
}

variable "docker_build_path" {
  description = "Base path for Docker builds (where app directories are located)"
  type        = string
  default     = "."
}

variable "force_delete" {
  description = "Force delete ECR repositories even if they contain images"
  type        = bool
  default     = true
}

variable "image_tag_mutability" {
  description = "Image tag mutability setting for ECR repositories"
  type        = string
  default     = "MUTABLE"
}

variable "scan_on_push" {
  description = "Enable image scanning on push"
  type        = bool
  default     = true
}

variable "repository_policies" {
  description = "Map of repository policies (JSON strings)"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}