# Terraform Outputs

# Cluster Information
output "cluster_name" {
  description = "GKE Cluster Name"
  value       = google_container_cluster.primary.name
}

output "cluster_location" {
  description = "GKE Cluster Location"
  value       = google_container_cluster.primary.location
}

output "cluster_endpoint" {
  description = "GKE Cluster Endpoint"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "GKE Cluster CA Certificate"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

# Node Pool Information
output "node_pool_name" {
  description = "GKE Node Pool Name"
  value       = google_container_node_pool.primary_nodes.name
}

# Commands to Access Cluster
output "configure_kubectl_command" {
  description = "Command to configure kubectl"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --zone=${var.zone} --project=${var.project_id}"
}

output "get_loadbalancer_ip_command" {
  description = "Command to get the LoadBalancer external IP"
  value       = "kubectl get service hello-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}'"
}

output "get_pods_command" {
  description = "Command to view pods"
  value       = "kubectl get pods -l app=hello-app"
}

output "get_service_command" {
  description = "Command to view service details"
  value       = "kubectl get service hello-app"
}

# Helpful information
output "project_id" {
  description = "GCP Project ID"
  value       = var.project_id
}

output "region" {
  description = "GCP Region"
  value       = var.region
}
