# Enable compute API
resource "google_project_service" "compute" {
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

# Enable Artifact Registry API
resource "google_project_service" "artifactregistry" {
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

# Enable Cloud Build API
resource "google_project_service" "cloudbuild" {
  service            = "cloudbuild.googleapis.com"
  disable_on_destroy = false
}


### Create an HTTPS Load Balancer ###

# Create a global IP address for the load balancer
resource "google_compute_global_address" "frontend_ip" {
  name = "frontend"
  purpose = "GLOBAL"
}

# Create a backend service
resource "google_compute_backend_service" "backend_service" {
  name = "my-backend-service"

  backend {
    group = google_cloud_run_service.backend.status.0.url
  }

  health_checks = [
    google_compute_health_check.backend_health_check.self_link
  ]

  port_name        = "http"
  protocol         = "HTTP"
  timeout_sec      = 10
  connection_draining_timeout_sec = 10
}

# Create a URL map
resource "google_compute_url_map" "url_map" {
  name            = "url-map"
  default_service = google_compute_backend_service.backend_service.self_link
}

# Create a health check for the backend
resource "google_compute_health_check" "backend_health_check" {
  name = "backend-health-check"

  http_health_check {
    port = 443
  }
}

# Create a target HTTP proxy
resource "google_compute_target_http_proxy" "http_proxy" {
  name   = "my-http-proxy"
  url_map = google_compute_url_map.url_map.self_link
}

# Create a backend service
resource "google_compute_backend_service" "backend_service" {
  name = "my-backend-service"

  backend {
    group = google_cloud_run_service.backend.status.0.url
  }

  health_checks = [
    google_compute_health_check.backend_health_check.self_link
  ]

  port_name        = "http"
  protocol         = "HTTP"
  timeout_sec      = 10
  connection_draining_timeout_sec = 10
}

# Create a global forwarding rule
resource "google_compute_global_forwarding_rule" "https_forwarding_rule" {
  name        = "forwarding-rule-https"
  target      = google_compute_target_https_proxy.https_proxy.self_link
  port_range  = "443"
  ip_address  = google_compute_global_address.frontend_ip.id
  ip_protocol = "TCP"
}

# Create a Google Managed SSL Certificate
resource "google_compute_managed_ssl_certificate" "managed_ssl_cert" {
  name = "managed-ssl-certificate"
  managed {
    domains = var.my_domains
  }
}

output "load_balancer_ip_addr" {
  value = google_compute_global_address.frontend_ip.address
}