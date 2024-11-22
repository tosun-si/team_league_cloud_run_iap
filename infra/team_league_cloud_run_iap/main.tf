# resource "google_vpc_access_connector" "cloud_run_vpc_connector_iap" {
#   name          = "cloud-run-vpc-conn-iap"
#   region        = var.region
#   project       = var.project_id
#   ip_cidr_range = "10.9.0.0/28"
#   network       = "default"
#   min_instances = 2
#   max_instances = 10
# }

resource "random_id" "random_suffix" {
  byte_length = 4
}

resource "google_compute_url_map" "url_map" {
  project = var.project_id
  name    = "cloud-run-url-map-${random_id.random_suffix.hex}"

  default_url_redirect {
    https_redirect         = false
    host_redirect          = "www.google.com"
    redirect_response_code = "PERMANENT_REDIRECT"
    strip_query            = true
  }

  host_rule {
    hosts = [var.domain]
    path_matcher = "cloud-iap"
  }

  path_matcher {
    name = "cloud-iap"

    default_service = module.lb-http.backend_services["default"].self_link
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_cloud_run_service" "team_league_cloud_run_service" {
  name     = var.service_name
  location = var.region
  project  = var.project_id

  metadata {
    annotations = {
      "run.googleapis.com/ingress" : "internal-and-cloud-load-balancing"
    }
  }
  template {
    # metadata {
    #   annotations = {
    #     "run.googleapis.com/vpc-access-connector" : google_vpc_access_connector.cloud_run_vpc_connector_iap.name
    #   }
    # }

    spec {
      containers {
        image = "${var.region}-docker.pkg.dev/${var.project_id}/${var.repo_name}/${var.image_name}:${var.image_tag}"
      }
    }
  }
}

resource "google_compute_region_network_endpoint_group" "serverless_neg" {
  project               = var.project_id
  provider              = google
  name                  = "serverless-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    service = google_cloud_run_service.team_league_cloud_run_service.name
  }
}

module "lb-http" {
  source  = "GoogleCloudPlatform/lb-http/google//modules/serverless_negs"
  version = "12.0.0"

  project = var.project_id
  name    = var.lb_name

  ssl                       = true
  managed_ssl_certificate_domains = [var.domain]
  https_redirect            = true
  random_certificate_suffix = true

  url_map = google_compute_url_map.url_map.self_link

  backends = {
    default = {
      description = null
      groups = [
        {
          group = google_compute_region_network_endpoint_group.serverless_neg.id
        }
      ]
      # protocol               = "HTTPS"
      enable_cdn             = false
      security_policy        = null
      custom_request_headers = null

      iap_config = {
        enable               = true
        oauth2_client_id     = var.iap_client_id
        oauth2_client_secret = var.iap_client_secret
      }
      log_config = {
        enable      = false
        sample_rate = null
      }
    }
  }
}

data "google_iam_policy" "cloud_run_iap" {
  binding {
    role = "roles/iap.httpsResourceAccessor"
    members = [
      "group:gcp-group-test@groupbees.fr", // a google group
      // "allAuthenticatedUsers"          // anyone with a Google account (not recommended)
      // "user:ahmetalpbalkan@gmail.com", // a particular user
    ]
  }
}

resource "google_iap_web_backend_service_iam_policy" "policy" {
  project             = var.project_id
  web_backend_service = "${var.lb_name}-backend-default"
  policy_data         = data.google_iam_policy.cloud_run_iap.policy_data
  depends_on = [
    module.lb-http
  ]
}

output "load-balancer-ip" {
  value = module.lb-http.external_ip
}

output "oauth2-redirect-uri" {
  value = "https://iap.googleapis.com/v1/oauth/clientIds/${var.iap_client_id}:handleRedirect"
}