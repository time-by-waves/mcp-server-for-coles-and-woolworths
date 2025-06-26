# Kubernetes MCP Servers Deployment

This directory contains Kubernetes manifests for deploying your MCP servers.

## Quick Start

```bash
# Make deployment script executable
chmod +x k8s/deploy.sh

# Run deployment
./k8s/deploy.sh
```

## Manual Deployment

```bash
# Deploy all services
kubectl apply -f k8s/python-deployment.yaml
kubectl apply -f k8s/bash-deployment.yaml
kubectl apply -f k8s/powershell-deployment.yaml

# Optional: Deploy ingress
kubectl apply -f k8s/ingress.yaml

# Optional: Deploy auto-scaling
kubectl apply -f k8s/hpa.yaml
```

## Resource Requirements

| Service    | CPU Request | Memory Request | CPU Limit | Memory Limit |
|------------|-------------|----------------|-----------|--------------|
| Python     | 50m         | 64Mi           | 100m      | 128Mi        |
| Bash       | 25m         | 32Mi           | 50m       | 64Mi         |
| PowerShell | 100m        | 128Mi          | 200m      | 256Mi        |

**Total cluster minimum**: ~175m CPU, ~224Mi RAM per replica set

## Cost Estimates

### Small Cluster (3 nodes, 1 vCPU, 1GB each)
- **Civo**: $20/month
- **DigitalOcean**: $30/month
- **Linode**: $30/month

### Single Node (K3s)
- **Hetzner**: $3.50/month
- **Vultr**: $5/month

## Accessing Services

```bash
# Port forward to access locally
kubectl port-forward -n mcp-servers service/mcp-server-python-service 8000:80
kubectl port-forward -n mcp-servers service/mcp-server-bash-service 8001:80
kubectl port-forward -n mcp-servers service/mcp-server-powershell-service 8002:80

# Test endpoints
curl http://localhost:8000/
curl http://localhost:8001/
curl http://localhost:8002/
```

## Scaling

```bash
# Manual scaling
kubectl scale deployment mcp-server-python --replicas=5 -n mcp-servers

# Check HPA status
kubectl get hpa -n mcp-servers
```

## Monitoring

```bash
# Check pod status
kubectl get pods -n mcp-servers

# View logs
kubectl logs -f deployment/mcp-server-python -n mcp-servers

# Resource usage
kubectl top pods -n mcp-servers
```
