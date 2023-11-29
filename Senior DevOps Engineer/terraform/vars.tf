variable "project" {
  description = "The billing enabled GCP project id which will host your resources"
  type        = string
}

variable "region" {
  description = "GCP region e.g. australia-southeast1"
  type        = string
}

variable "domains" {
  description = "Domain name for which the Google managed SSL certificate will be valid. This needs to be configured at your DNS service provider."
}