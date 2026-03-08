# GKE Cluster Configuration
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.zone  # Zonal cluster for simplicity

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  # Network configuration - using default VPC
  network    = "default"
  subnetwork = "default"

  # Enable Workload Identity (best practice)
  # to enable Workload Identity for a Google Kubernetes Engine (GKE) cluster or node pool
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Maintenance window
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }
}

# Separately Managed Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.cluster_name}-node-pool"
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  node_count = 1  # Number of nodes per zone

  # Auto-scaling configuration (optional but recommended)
  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }

  # Node configuration
  node_config {
    machine_type = "e2-medium"
    disk_size_gb = 30
    disk_type    = "pd-standard"

    # OAuth scopes for node access
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Metadata
    metadata = {
      disable-legacy-endpoints = "true"
    }

    # Workload Identity
    # This setting is a key component for implementing Workload Identity, which allows Kubernetes pods to securely access Google Cloud
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Labels
    labels = {
      environment = "demo"
      managed-by  = "terraform"
    }

    # Tags for firewall rules
    # The tags in your firewall rule configuration are network tags used to apply VPC firewall rules to specific GKE node instances
    tags = ["gke-node", "${var.cluster_name}-node"]
  }

  # Node management
  # to automatically manage the health and versioning of Kubernetes cluster
  management {
    auto_repair  = true
    auto_upgrade = true
  }
}
