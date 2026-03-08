# Helm Release Configuration
# This deploys the hello-app Helm chart to the GKE cluster

resource "helm_release" "hello_app" {
  name       = "hello-app"
  chart      = "../hello-chart"
  namespace  = "default"
  
  # Wait for the release to be deployed successfully
  wait       = true
  timeout    = 300  # 5 minutes timeout

  # Set values from Terraform variables
  set {
    name  = "replicaCount"
    value = 3
  }

  set {
    name  = "service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "service.port"
    value = 80
  }

  # Ensure the node pool is ready before deploying
  depends_on = [
    google_container_node_pool.primary_nodes
  ]
}

# Output the Helm release status
output "helm_release_status" {
  description = "Status of the Helm release"
  value       = helm_release.hello_app.status
}

output "helm_release_version" {
  description = "Version of the Helm release"
  value       = helm_release.hello_app.version
}
