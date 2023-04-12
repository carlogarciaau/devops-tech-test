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

# Enable VPC Access API
resource "google_project_service" "vpcaccess" {
  service            = "vpcaccess.googleapis.com"
  disable_on_destroy = false
}

# Create a VPC
resource "google_compute_network" "vpc" {
  name = "my-vpc"
}

# Create a subnet in the VPC
resource "google_compute_subnetwork" "subnet" {
  name          = "my-subnet"
  network       = google_compute_network.vpc.self_link
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
}

# Create a VPC connector for Cloud Run
resource "google_vpc_access_connector" "connector" {
  name          = "my-vpc-connector"
  region        = var.region
  network       = google_compute_network.vpc.name
  ip_cidr_range = "10.8.0.0/28"
}


# Create a Cloud Run service
resource "google_cloud_run_service" "backend" {
  name     = "flask-hello-world"
  location = var.region

  template {
    spec {
      containers {
        image = "${var.region}-docker.pkg.dev/flask-deployment-test-383404/docker-repo-test/flask-hello:TEST"
      }
    }

    metadata {
      annotations = {
        # Limit scale up to prevent any cost blow outs!
        "autoscaling.knative.dev/maxScale" = "5"
        # Use the VPC Connector
        "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.connector.name
        # all egress from the service should go through the VPC Connector
        "run.googleapis.com/vpc-access-egress" = "all-traffic"
      }
    }
  }
}

# Create a network endpoint group out of the serverless service
resource "google_compute_region_network_endpoint_group" "cloudrun_neg" {
  name                  = "serverless-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    service = google_cloud_run_service.backend.name
  }
}

# Create an ingress firewall rule to allow traffic from the VPC
resource "google_compute_firewall" "allow_vpc_traffic" {
  name    = "allow-vpc-traffic"
  network = google_compute_network.vpc.self_link

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = [google_compute_subnetwork.subnet.ip_cidr_range]
}

### Create an HTTPS Load Balancer ###

# Create a global IP address for the load balancer
resource "google_compute_global_address" "frontend_ip" {
  name    = "frontend"
  purpose = "GLOBAL"
}

# Create a backend service
resource "google_compute_backend_service" "backend_service" {
  name            = "serverless-backend-service"
  enable_cdn      = true
  security_policy = google_compute_security_policy.policy.self_link
  cdn_policy {
    signed_url_cache_max_age_sec = 7200
  }

  backend {
    group = google_compute_region_network_endpoint_group.cloudrun_neg.id
  }

}

# Create a URL map
resource "google_compute_url_map" "url_map" {
  name            = "url-map"
  default_service = google_compute_backend_service.backend_service.id
}


# Create a target HTTPS proxy
resource "google_compute_target_https_proxy" "https_proxy" {
  name             = "https-proxy"
  url_map          = google_compute_url_map.url_map.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.managed_ssl_cert.id]
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
    domains = var.domains
  }
}

# Create Security Policy
resource "google_compute_security_policy" "policy" {
  name = "security-policy"

  rule {
    action   = "allow"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "default rule"
  }
}

output "load_balancer_ip_addr" {
  value = google_compute_global_address.frontend_ip.address
}