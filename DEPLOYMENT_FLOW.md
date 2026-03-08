# 📋 Deployment Flow Explanation

This document explains the complete deployment flow from Terraform to Kubernetes.

## 🔄 Complete Deployment Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                     TERRAFORM EXECUTION                          │
└─────────────────────────────────────────────────────────────────┘

1. terraform init
   ├─ Downloads provider plugins
   │  ├─ hashicorp/google (~> 5.0)
   │  ├─ hashicorp/kubernetes (~> 2.23)
   │  └─ hashicorp/helm (~> 2.11)
   └─ Initializes backend

2. terraform plan
   ├─ Reads configuration files
   ├─ Queries GCP API for current state
   └─ Generates execution plan

3. terraform apply
   │
   ├─── PHASE 1: GCP Infrastructure (5-7 minutes)
   │    │
   │    ├─ Create GKE Cluster
   │    │  ├─ Cluster control plane
   │    │  ├─ Network configuration (default VPC)
   │    │  ├─ Enable Workload Identity
   │    │  └─ Configure maintenance window
   │    │
   │    └─ Create Node Pool
   │       ├─ Launch e2-medium VM instances
   │       ├─ Configure auto-scaling (1-3 nodes)
   │       ├─ Enable auto-repair and auto-upgrade
   │       └─ Apply security configurations
   │
   ├─── PHASE 2: Provider Configuration (< 1 minute)
   │    │
   │    ├─ Kubernetes Provider
   │    │  ├─ Fetch cluster endpoint
   │    │  ├─ Get authentication token
   │    │  └─ Retrieve CA certificate
   │    │
   │    └─ Helm Provider
   │       ├─ Use Kubernetes credentials
   │       └─ Initialize Helm client
   │
   └─── PHASE 3: Application Deployment (2-3 minutes)
        │
        └─ Deploy Helm Release
           ├─ Read hello-chart/ directory
           ├─ Process Chart.yaml
           ├─ Load values.yaml
           ├─ Render templates with values
           │
           ├─── CREATE: Deployment
           │    ├─ Create ReplicaSet
           │    └─ Launch 3 nginx pods
           │       ├─ Pull nginx:1.25-alpine image
           │       ├─ Start containers
           │       ├─ Run liveness probes
           │       └─ Run readiness probes
           │
           └─── CREATE: Service (LoadBalancer)
                ├─ Create Service object in Kubernetes
                ├─ Kubernetes triggers GCP LoadBalancer creation
                ├─ GCP provisions external forwarding rule
                ├─ Assign external IP address
                └─ Configure backend to pods (port 80)

✅ Deployment Complete!

┌─────────────────────────────────────────────────────────────────┐
│                     KUBERNETES RUNTIME                           │
└─────────────────────────────────────────────────────────────────┘

Traffic Flow:
Internet → External IP → LoadBalancer → Service → Pod (Round-robin)

Monitoring:
├─ Kubelet runs health checks every 10s
├─ Failed pods automatically restarted
└─ Auto-scaling adjusts nodes based on load
```

## 🔍 Detailed Phase Breakdown

### Phase 1: Infrastructure Creation (Terraform → GCP)

**What Terraform Does:**
1. Calls GCP Container API to create cluster
2. Waits for cluster to be "RUNNING"
3. Creates node pool attached to cluster
4. Waits for nodes to be "READY"

**What GCP Does:**
1. Provisions control plane VMs (managed by Google)
2. Configures networking and firewall rules
3. Launches worker node VMs in your project
4. Installs Kubernetes components on nodes
5. Joins nodes to cluster

**Key Resources Created:**
- `google_container_cluster.primary` → GKE Cluster
- `google_container_node_pool.primary_nodes` → Node Pool
- Compute Engine VMs (worker nodes)
- Firewall rules for cluster communication

### Phase 2: Provider Configuration (Dynamic)

**Kubernetes Provider:**
```hcl
provider "kubernetes" {
  host                   = "https://${google_container_cluster.primary.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(...)
}
```

**How it Works:**
1. Terraform reads cluster endpoint from state
2. Uses `gcloud` credentials for authentication
3. Establishes connection to Kubernetes API server
4. Validates connectivity

**Helm Provider:**
```hcl
provider "helm" {
  kubernetes {
    host  = "https://${google_container_cluster.primary.endpoint}"
    token = data.google_client_config.default.access_token
    ...
  }
}
```

**How it Works:**
1. Inherits Kubernetes connection details
2. Initializes Helm client (v3 - no Tiller)
3. Ready to deploy charts

### Phase 3: Helm Deployment (Helm → Kubernetes)

**Step 1: Chart Processing**
```
hello-chart/
├── Chart.yaml           → Read metadata
├── values.yaml          → Load default values
└── templates/
    ├── deployment.yaml  → Template rendering
    └── service.yaml     → Template rendering
```

**Step 2: Template Rendering**

Helm replaces template variables:
```yaml
# Template
replicas: {{ .Values.replicaCount }}

# Rendered
replicas: 3
```

**Step 3: Kubernetes Resource Creation**

Helm applies rendered manifests:
```bash
# Equivalent to:
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

**Step 4: Kubernetes Reconciliation**

1. **Deployment Controller:**
   - Sees new Deployment object
   - Creates ReplicaSet
   - Calculates desired vs current state
   - Instructs scheduler to launch pods

2. **Scheduler:**
   - Selects best node for each pod
   - Considers resources, affinity rules
   - Assigns pods to nodes

3. **Kubelet (on each node):**
   - Receives pod assignment
   - Pulls container image
   - Starts containers
   - Reports status back to API server

4. **Service Controller:**
   - Sees Service type=LoadBalancer
   - Calls GCP API to provision LoadBalancer
   - Waits for external IP assignment
   - Updates Service object with IP

5. **LoadBalancer Provisioning (GCP):**
   - Creates forwarding rule
   - Allocates external IP
   - Configures backend pool (pod IPs)
   - Sets up health checks

## 🔗 Dependency Chain

```
GKE Cluster
    ↓
Node Pool (depends_on cluster)
    ↓
Kubernetes Provider (uses cluster endpoint)
    ↓
Helm Provider (uses kubernetes config)
    ↓
Helm Release (depends_on node_pool)
    ↓
Kubernetes Deployment
    ↓
Pods (managed by ReplicaSet)
    ↓
Service (targets pods via selectors)
    ↓
LoadBalancer (provisioned by GCP)
    ↓
External IP (assigned to LoadBalancer)
```

## 🎯 Key Concepts

### Terraform's Role
- **Infrastructure Layer**: Creates GCP resources
- **Orchestration**: Manages dependencies
- **State Management**: Tracks resource status
- **Idempotent**: Safe to run multiple times

### Helm's Role
- **Package Manager**: Bundles Kubernetes manifests
- **Templating**: Dynamic configuration
- **Release Management**: Versioning and rollbacks
- **Values Override**: Configuration flexibility

### Kubernetes' Role
- **Desired State**: Maintains declared configuration
- **Self-Healing**: Restarts failed pods
- **Service Discovery**: Routes traffic to healthy pods
- **Load Balancing**: Distributes requests

## 🔄 What Happens After Deployment?

### Continuous Operations

**Pod Lifecycle:**
1. Container runs nginx web server
2. Liveness probe checks health every 10s
3. Readiness probe determines if pod receives traffic
4. If unhealthy, Kubernetes restarts container
5. If repeatedly failing, pod is replaced

**Service Operation:**
1. LoadBalancer routes traffic to Service
2. Service distributes across all ready pods
3. Selector `app=hello-app` matches pods
4. Traffic distributed round-robin
5. Failed pods automatically removed from rotation

**Auto-Scaling:**
1. If CPU > 80%, node pool scales up
2. New node joins cluster automatically
3. Pods can be scheduled on new node
4. If load drops, nodes scale down
5. Pods gracefully moved before node removal

## 🛠️ How Terraform Manages This

### State Tracking
```
terraform.tfstate
├── google_container_cluster.primary
│   ├── id: "projects/.../clusters/hello-gke-cluster"
│   ├── endpoint: "35.x.x.x"
│   └── status: "RUNNING"
├── google_container_node_pool.primary_nodes
│   ├── id: "projects/.../nodePools/..."
│   └── node_count: 1
└── helm_release.hello_app
    ├── name: "hello-app"
    ├── version: "1"
    └── status: "deployed"
```

### Update Process (terraform apply)
1. Compare desired config vs current state
2. Calculate minimum changes needed
3. Apply changes in correct order
4. Update state file
5. Report changes made

### Destroy Process (terraform destroy)
1. Delete Helm release first
2. Kubernetes deletes pods and service
3. GCP removes LoadBalancer
4. Terraform deletes node pool
5. Finally deletes GKE cluster

## 📊 Timeline Summary

| Time      | Action                           | Component   |
|-----------|----------------------------------|-------------|
| 0:00      | terraform apply started          | Terraform   |
| 0:30      | GKE cluster creation begins      | GCP         |
| 5:00      | Cluster ready                    | GKE         |
| 5:30      | Node pool creation begins        | GCP         |
| 7:00      | Nodes ready                      | GKE         |
| 7:10      | Kubernetes provider configured   | Terraform   |
| 7:15      | Helm provider configured         | Terraform   |
| 7:20      | Helm chart processing            | Helm        |
| 7:30      | Deployment created               | Kubernetes  |
| 7:45      | Pods starting                    | Kubernetes  |
| 8:00      | Service created                  | Kubernetes  |
| 8:30      | LoadBalancer provisioned         | GCP         |
| 9:00      | External IP assigned             | GCP         |
| 9:30      | Health checks passing            | Kubernetes  |
| **10:00** | **✅ Application Ready**         | **All**     |

## 🎓 Learning Takeaways

1. **Terraform manages infrastructure** (GKE cluster, nodes)
2. **Helm manages applications** (Kubernetes resources)
3. **Kubernetes manages workloads** (pods, services)
4. **GCP provides compute** (VMs, networking, LoadBalancers)

This separation of concerns is a **DevOps best practice**:
- Infrastructure changes: Modify Terraform
- Application changes: Modify Helm chart
- Runtime operations: Use kubectl

---

**Next Steps:** Read [README.md](README.md) for deployment instructions!
