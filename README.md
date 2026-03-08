# GKE Hello World with Terraform and Helm

This project demonstrates production-quality infrastructure as code (IaC) practices for deploying a simple Hello World application to Google Kubernetes Engine (GKE) using Terraform and Helm.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                       Google Cloud Platform                  │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │              GKE Cluster (Zonal)                   │    │
│  │                                                     │    │
│  │  ┌──────────────────────────────────────────┐     │    │
│  │  │         Node Pool (e2-medium)            │     │    │
│  │  │                                           │     │    │
│  │  │  ┌────────────────────────────────┐     │     │    │
│  │  │  │  Hello-App Deployment          │     │     │    │
│  │  │  │  (3 replicas - nginx)          │     │     │    │
│  │  │  │  ┌──────┐ ┌──────┐ ┌──────┐  │     │     │    │
│  │  │  │  │ Pod1 │ │ Pod2 │ │ Pod3 │  │     │     │    │
│  │  │  │  └──────┘ └──────┘ └──────┘  │     │     │    │
│  │  │  └────────────────────────────────┘     │     │    │
│  │  │                 ▲                        │     │    │
│  │  │                 │                        │     │    │
│  │  │  ┌──────────────┴───────────────┐      │     │    │
│  │  │  │  LoadBalancer Service         │      │     │    │
│  │  │  │  (Port 80)                    │      │     │    │
│  │  │  └──────────────┬───────────────┘      │     │    │
│  │  └─────────────────┼────────────────────────┘     │    │
│  └────────────────────┼──────────────────────────────┘    │
│                       │                                    │
│         ┌─────────────┴──────────────┐                    │
│         │  External LoadBalancer IP   │                    │
│         │  (Public Internet Access)   │                    │
│         └─────────────┬──────────────┘                    │
└───────────────────────┼───────────────────────────────────┘
                        │
                        ▼
                   🌐 Internet
```

## 🚀 Deployment Flow

```
Terraform Init
     │
     ▼
Terraform Plan
     │
     ▼
Create GKE Cluster ──► Create Node Pool
     │                       │
     ▼                       ▼
Configure Kubernetes ──► Configure Helm Provider
     │                       │
     ▼                       ▼
Deploy Helm Chart ──────► Create Deployment (3 Pods)
                            │
                            ▼
                     Create LoadBalancer Service
                            │
                            ▼
                     Assign External IP
                            │
                            ▼
                     Application Ready! 🎉
```

## 📁 Project Structure

```
project/
├── README.md
├── .gitignore
├── terraform/
│   ├── provider.tf      # Provider configurations (GCP, Kubernetes, Helm)
│   ├── main.tf          # GKE cluster and node pool resources
│   ├── helm.tf          # Helm release configuration
│   └── outputs.tf       # Terraform outputs
│
└── hello-chart/
    ├── Chart.yaml       # Helm chart metadata
    ├── values.yaml      # Default configuration values
    └── templates/
        ├── deployment.yaml  # Kubernetes deployment template
        └── service.yaml     # Kubernetes service template
```

## 📋 Prerequisites

Before you begin, ensure you have the following installed and configured:

1. **Google Cloud SDK (gcloud)**
   ```bash
   # Install gcloud CLI
   curl https://sdk.cloud.google.com | bash
   exec -l $SHELL
   
   # Initialize and authenticate
   gcloud init
   gcloud auth application-default login
   ```

2. **Terraform** (>= 1.0)
   ```bash
   # macOS
   brew install terraform
   
   # Linux
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   ```

3. **kubectl**
   ```bash
   # macOS
   brew install kubectl
   
   # Linux
   gcloud components install kubectl
   ```

4. **Helm** (>= 3.0)
   ```bash
   # macOS
   brew install helm
   
   # Linux
   curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
   ```

5. **GCP Project Setup**
   ```bash
   # Set your project ID
   export PROJECT_ID="your-gcp-project-id"
   gcloud config set project $PROJECT_ID
   
   # Enable required APIs
   gcloud services enable container.googleapis.com
   gcloud services enable compute.googleapis.com
   ```

## 🔧 Configuration

1. **Set your GCP Project ID**

   Create a `terraform.tfvars` file in the `terraform/` directory:

   ```bash
   cd terraform
   cat > terraform.tfvars <<EOF
   project_id   = "your-gcp-project-id"
   region       = "us-central1"
   zone         = "us-central1-a"
   cluster_name = "hello-gke-cluster"
   EOF
   ```

   **Or** set the project ID via environment variable:
   ```bash
   export TF_VAR_project_id="your-gcp-project-id"
   ```

## 🚢 Deployment Steps

### Step 1: Initialize Terraform

```bash
cd terraform
terraform init
```

**Expected output:**
```
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/google versions matching "~> 5.0"...
- Finding hashicorp/kubernetes versions matching "~> 2.23"...
- Finding hashicorp/helm versions matching "~> 2.11"...

Terraform has been successfully initialized!
```

### Step 2: Review the Execution Plan

```bash
terraform plan
```

This command shows you what Terraform will create:
- GKE cluster
- Node pool with e2-medium instances
- Helm release deploying the hello-app chart

### Step 3: Apply the Configuration

```bash
terraform apply
```

Type `yes` when prompted to confirm.

**⏱️ Expected Duration:** 5-10 minutes

**What happens during apply:**
1. Creates GKE cluster (3-5 minutes)
2. Creates node pool with auto-scaling (2-3 minutes)
3. Configures Kubernetes and Helm providers
4. Deploys Helm chart with 3 nginx replicas
5. Creates LoadBalancer service
6. GCP assigns external IP address

### Step 4: Retrieve Terraform Outputs

```bash
terraform output
```

**Example output:**
```
cluster_name                  = "hello-gke-cluster"
configure_kubectl_command     = "gcloud container clusters get-credentials hello-gke-cluster --zone=us-central1-a --project=your-project-id"
get_loadbalancer_ip_command   = "kubectl get service hello-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}'"
get_pods_command              = "kubectl get pods -l app=hello-app"
get_service_command           = "kubectl get service hello-app"
helm_release_status           = "deployed"
helm_release_version          = "1"
```

## 🔍 Verification Steps

### 1. Configure kubectl

```bash
# Use the command from terraform output
gcloud container clusters get-credentials hello-gke-cluster --zone=us-central1-a --project=your-project-id
```

### 2. Verify Pods are Running

```bash
kubectl get pods -l app=hello-app
```

**Expected output:**
```
NAME                         READY   STATUS    RESTARTS   AGE
hello-app-xxxxxxxxx-xxxxx    1/1     Running   0          2m
hello-app-xxxxxxxxx-xxxxx    1/1     Running   0          2m
hello-app-xxxxxxxxx-xxxxx    1/1     Running   0          2m
```

### 3. Check Service Status

```bash
kubectl get service hello-app
```

**Expected output:**
```
NAME        TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)        AGE
hello-app   LoadBalancer   10.xx.xxx.xxx   34.xx.xxx.xxx    80:xxxxx/TCP   3m
```

**Note:** It may take 1-2 minutes for the EXTERNAL-IP to be assigned.

### 4. Get the LoadBalancer IP

```bash
kubectl get service hello-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

**Or use the simplified command:**
```bash
export EXTERNAL_IP=$(kubectl get service hello-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Application URL: http://$EXTERNAL_IP"
```

### 5. Test the Application

```bash
curl http://$EXTERNAL_IP
```

**Or** open in your browser:
```bash
# macOS
open "http://$EXTERNAL_IP"

# Linux
xdg-open "http://$EXTERNAL_IP"
```

You should see the default Nginx welcome page! 🎉

## 📊 Monitoring and Management

### View Deployment Details

```bash
kubectl describe deployment hello-app
```

### View Logs

```bash
# Logs from all pods
kubectl logs -l app=hello-app

# Logs from a specific pod
kubectl logs <pod-name>

# Follow logs in real-time
kubectl logs -f -l app=hello-app
```

### Scale the Deployment

```bash
# Scale to 5 replicas
kubectl scale deployment hello-app --replicas=5

# Verify scaling
kubectl get pods -l app=hello-app
```

### Check Helm Release

```bash
# List Helm releases
helm list

# Get release details
helm status hello-app

# View release history
helm history hello-app
```

### Access GKE Dashboard

```bash
# Open GKE cluster in Cloud Console
gcloud container clusters describe hello-gke-cluster --zone=us-central1-a
```

## 🔧 Customization

### Change Number of Replicas

**Option 1: Update Terraform**

Edit `terraform/helm.tf`:
```hcl
set {
  name  = "replicaCount"
  value = 5  # Change from 3 to 5
}
```

Then apply:
```bash
terraform apply
```

**Option 2: Update Helm Values**

Edit `hello-chart/values.yaml`:
```yaml
replicaCount: 5
```

Then upgrade:
```bash
helm upgrade hello-app ../hello-chart
```

### Use a Different Container Image

Edit `hello-chart/values.yaml`:
```yaml
image:
  repository: gcr.io/google-samples/hello-app
  tag: "1.0"
```

Apply changes:
```bash
terraform apply
```

### Add Custom HTML Content

Create a ConfigMap with custom content:
```bash
kubectl create configmap nginx-content --from-literal=index.html="<h1>Hello from GKE!</h1>"
```

Update the deployment to mount it (requires chart modification).

## 🧹 Cleanup

### Destroy All Resources

```bash
cd terraform
terraform destroy
```

Type `yes` when prompted.

**What gets deleted:**
- Helm release
- Kubernetes resources (Deployment, Service, Pods)
- Node pool
- GKE cluster
- LoadBalancer (and external IP)

**⏱️ Duration:** 5-10 minutes

**💰 Cost Note:** This prevents ongoing GCP charges!

### Verify Cleanup

```bash
# Check if cluster is deleted
gcloud container clusters list

# Check if LoadBalancer is deleted
gcloud compute forwarding-rules list
```

## 💡 Best Practices Implemented

✅ **Infrastructure as Code**: All infrastructure defined in Terraform
✅ **Immutable Deployments**: Using Helm for version-controlled releases
✅ **Separation of Concerns**: Terraform manages infrastructure, Helm manages applications
✅ **Resource Management**: CPU/Memory limits and requests defined
✅ **Health Checks**: Liveness and readiness probes configured
✅ **Auto-scaling**: Node pool auto-scaling enabled (1-3 nodes)
✅ **Auto-healing**: Node auto-repair enabled
✅ **Security**: Workload Identity enabled, legacy endpoints disabled
✅ **High Availability**: 3 replicas for redundancy
✅ **Proper Dependencies**: Helm deployment waits for node pool creation

## 🔍 Troubleshooting

### Issue: Terraform fails with authentication error

**Solution:**
```bash
gcloud auth application-default login
gcloud config set project your-project-id
```

### Issue: LoadBalancer stuck in "Pending"

**Check:**
```bash
kubectl describe service hello-app
```

**Common causes:**
- Insufficient GCP quotas
- Network firewall rules
- Wait 2-3 minutes for IP assignment

### Issue: Pods not starting

**Check pod status:**
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

**Common causes:**
- Image pull errors
- Resource constraints
- Node not ready

### Issue: Cannot connect to external IP

**Check firewall rules:**
```bash
gcloud compute firewall-rules list
```

**Test from Cloud Shell:**
```bash
curl http://$EXTERNAL_IP
```

### Issue: Helm chart not found

**Verify path:**
```bash
ls -la ../hello-chart
```

Make sure you're running Terraform from the `terraform/` directory.

## 📚 Additional Resources

- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## 🎓 Understanding the Components

### Terraform Components

- **provider.tf**: Configures GCP, Kubernetes, and Helm providers with proper authentication
- **main.tf**: Defines GKE cluster and node pool resources
- **helm.tf**: Deploys the Helm chart using the `helm_release` resource
- **outputs.tf**: Exports useful information and commands

### Helm Chart Components

- **Chart.yaml**: Metadata about the Helm chart (name, version, description)
- **values.yaml**: Default configuration values (replicas, image, service type)
- **templates/deployment.yaml**: Kubernetes Deployment template with Go templating
- **templates/service.yaml**: Kubernetes Service template (LoadBalancer type)

### Kubernetes Resources Created

1. **Deployment**: Manages 3 replica pods running nginx
2. **Service**: LoadBalancer type, exposes pods on port 80
3. **Pods**: Individual instances of the nginx container

## 🔐 Security Considerations

For production use, consider:

1. **Private GKE Cluster**: Enable private nodes and master
2. **Network Policies**: Restrict pod-to-pod communication
3. **Workload Identity**: Already enabled for pod authentication
4. **Binary Authorization**: Enforce container image signatures
5. **Pod Security Policies**: Enforce security standards
6. **HTTPS/TLS**: Use Ingress with SSL certificates
7. **Secret Management**: Use Google Secret Manager
8. **RBAC**: Implement role-based access control

## 📝 License

This project is provided as-is for educational and demonstration purposes.

---

**Built with ❤️ by DevOps Team**
