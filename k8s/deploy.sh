#!/bin/bash

# Kubernetes Deployment Script for MCP Servers
set -e

echo "🚀 Deploying MCP Servers to Kubernetes..."

# Check if kubectl is installed
if ! command -v kubectl &>/dev/null; then
  echo "❌ kubectl is not installed. Please install kubectl first."
  exit 1
fi

# Check cluster connectivity
echo "🔍 Checking cluster connectivity..."
if ! kubectl cluster-info &>/dev/null; then
  echo "❌ Cannot connect to Kubernetes cluster. Please check your kubeconfig."
  exit 1
fi

echo "✅ Connected to cluster: $(kubectl config current-context)"

# Build and tag Docker images
echo "🐳 Building Docker images..."

echo "Building Python image..."
docker build -t mcp-server-python:latest .

echo "Building PowerShell image..."
docker build -f DOCKERFILE.pwsh -t mcp-server-powershell:latest .

echo "Building Bash image..."
docker build -f Dockerfile.bash -t mcp-server-bash:latest .

# If using a registry, push images
read -p "🏗️  Do you want to push images to a registry? (y/N): " -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
  read -p "Enter your registry URL (e.g., your-registry.com/): " registry_url

  # Tag and push images
  for image in python powershell bash; do
    echo "Pushing mcp-server-${image}..."
    docker tag mcp-server-${image}:latest ${registry_url}mcp-server-${image}:latest
    docker push ${registry_url}mcp-server-${image}:latest

    # Update deployment files with registry URL
    sed -i "s|image: mcp-server-${image}:latest|image: ${registry_url}mcp-server-${image}:latest|g" k8s/${image}-deployment.yaml
  done
fi

# Deploy to Kubernetes
echo "📦 Deploying to Kubernetes..."

# Create namespace and deploy base configuration
kubectl apply -f k8s/python-deployment.yaml

# Deploy other services
kubectl apply -f k8s/bash-deployment.yaml
kubectl apply -f k8s/powershell-deployment.yaml

# Deploy ingress (optional)
read -p "🌐 Do you want to deploy ingress? (y/N): " -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
  read -p "Enter your domain name: " domain_name
  sed -i "s|your-domain.com|${domain_name}|g" k8s/ingress.yaml
  kubectl apply -f k8s/ingress.yaml
fi

# Deploy HPA (optional)
read -p "📈 Do you want to deploy Horizontal Pod Autoscaler? (y/N): " -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
  kubectl apply -f k8s/hpa.yaml
fi

echo "✅ Deployment complete!"

# Show status
echo "📊 Current status:"
kubectl get pods -n mcp-servers
kubectl get services -n mcp-servers

echo ""
echo "🎯 To access your services:"
echo "kubectl port-forward -n mcp-servers service/mcp-server-python-service 8000:80"
echo "kubectl port-forward -n mcp-servers service/mcp-server-bash-service 8001:80"
echo "kubectl port-forward -n mcp-servers service/mcp-server-powershell-service 8002:80"

echo ""
echo "📝 To update your deployment:"
echo "kubectl set image deployment/mcp-server-python mcp-server-python=mcp-server-python:new-tag -n mcp-servers"

echo ""
echo "🗑️  To cleanup:"
echo "kubectl delete namespace mcp-servers"
