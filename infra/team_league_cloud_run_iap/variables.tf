variable "project_id" {
  type = string
}

variable "region" {
  description = "Location for load balancer and Cloud Run resources"
  default     = "europe-west1"
}

variable "repo_name" {
  description = "AR repo name."
  type        = string
}

variable "image_name" {
  description = "Cloud Run image name."
  type        = string
}

variable "image_tag" {
  description = "Cloud Run image tag."
  type        = string
}

variable "service_name" {
  description = "Cloud Run service name."
  type        = string
}

variable "domain" {
  description = "Domain name to run the load balancer on."
  type        = string
}

variable "lb_name" {
  description = "Name for load balancer and associated resources"
  default     = "iap-lb"
}

variable "iap_client_id" {
  type      = string
  sensitive = false
}

variable "iap_client_secret" {
  type      = string
  sensitive = true
}