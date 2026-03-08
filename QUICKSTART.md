# 🚀 Quick Start Guide

Get your Hello World app running on GKE in 5 minutes!

## Prerequisites Checklist

- [ ] Google Cloud account with billing enabled
- [ ] `gcloud` CLI installed and authenticated
- [ ] `terraform` installed (>= 1.0)
- [ ] `kubectl` installed
- [ ] `helm` installed (>= 3.0)

## Step-by-Step Deployment

### 1️⃣ Enable GCP APIs (1 minute)

```bash
# Set your project ID
export PROJECT_ID="your-gcp-project-id"
gcloud config set project $PROJECT_ID

# Enable required APIs
gcloud services enable container.googleapis.com compute.googleapis.com
```

### 2️⃣ Configure Terraform (30 seconds)

```bash
cd terraform

# Create terraform.tfvars file
cat > terraform.tfvars <<EOF
project_id = "$PROJECT_ID"
EOF
```

### 3️⃣ Deploy Infrastructure (8-10 minutes)

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
# Type 'yes' when prompted
```

☕ **Grab a coffee!** This takes about 8-10 minutes.

### 4️⃣ Configure kubectl (30 seconds)

```bash
# Get credentials (replace with your actual project ID and zone)
gcloud container clusters get-credentials hello-gke-cluster \
  --zone=us-central1-a \
  --project=$PROJECT_ID
```

### 5️⃣ Verify Deployment (1 minute)

```bash
# Check pods are running
kubectl get pods -l app=hello-app

# Get the external IP (wait if still pending)
kubectl get service hello-app

# Get just the IP address
export EXTERNAL_IP=$(kubectl get service hello-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Your app is running at: http://$EXTERNAL_IP"
```

### 6️⃣ Access Your Application! 🎉

```bash
# Test with curl
curl http://$EXTERNAL_IP

# Or open in browser
open "http://$EXTERNAL_IP"  # macOS
xdg-open "http://$EXTERNAL_IP"  # Linux
```

You should see the Nginx welcome page!

## Common Commands

```bash
# View pods
kubectl get pods -l app=hello-app

# View logs
kubectl logs -l app=hello-app

# Scale deployment
kubectl scale deployment hello-app --replicas=5

# Check Helm release
helm list
helm status hello-app
```

## 🧹 Cleanup (When Done)

```bash
cd terraform
terraform destroy
# Type 'yes' when prompted
```

This deletes everything and stops billing.

## 🆘 Troubleshooting

**Issue: Authentication error**
```bash
gcloud auth application-default login
```

**Issue: External IP stuck in "Pending"**
- Wait 2-3 minutes
- Check: `kubectl describe service hello-app`

**Issue: Pods not starting**
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

## 📚 Next Steps

- Read the full [README.md](README.md) for detailed documentation
- Customize the deployment in `hello-chart/values.yaml`
- Add your own custom application
- Implement HTTPS with Ingress and certificates

---

**Need help?** Check the full [README.md](README.md) for detailed troubleshooting and architecture explanation.
