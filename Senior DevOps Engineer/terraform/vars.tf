variable "project" {
  description = "The billing enabled GCP project id which will host your resources"
  type        = string
}

variable "region" {
  description = "GCP region e.g. australia-southeast1"
  type        = string
}

variable "bucket_name" {
  description = "Bucket to host static files"
}

variable "my_domains" {
  description = "List of domain names for which the Google managed SSL certificate will be valid. This needs to be configured at your DNS service provider."
}