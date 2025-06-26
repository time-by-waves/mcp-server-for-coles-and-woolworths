# MCP Server for Coles and Woolworths

A Model Context Protocol (MCP) server that provides API access to Coles and Woolworths product and pricing data.

## Available Endpoints

- `/` - Discovery endpoint listing all available endpoints
- `/coles/price-changes/` - Get Coles price changes
- `/coles/product-search/` - Search Coles products
- `/woolworths/price-changes/` - Get Woolworths price changes
- `/woolworths/barcode-search/{barcode}` - Search by barcode in Woolworths
- `/woolworths/product-search/` - Search Woolworths products

## Running the MCP Server

### Python Version

1. Install dependencies: `pip install requests`
2. Run the server: `python src/server.py`
3. Server will start on <http://localhost:8000>

### PowerShell Version

1. Run the server: `pwsh src/server.ps1`
2. Optional parameters:
   - `-port 8080` (default: 8000)
   - `-rapidApiKey "your-key"` (default: embedded key)
   - `-hostPrefix "http://localhost"` (default: <http://localhost>)

### Bash Version

1. Make the script executable: `chmod +x src/server.sh`
2. Run the server: `./src/server.sh`
3. Requires: `bash`, `curl`, `netcat` (nc)
4. Environment variables:
   - `PORT=8080` (default: 8000)
   - `RAPIDAPI_KEY="your-key"` (default: embedded key)

## Docker Deployment

### Python Docker Container

```bash
# Build the image
docker build -t mcp-server-python .

# Run the container
docker run -d --name mcp-server-python -p 8000:8000 mcp-server-python
```

### PowerShell Docker Container

```bash
# Build the image
docker build -f DOCKERFILE.pwsh -t mcp-server-powershell .

# Run the container
docker run -d --name mcp-server-powershell -p 8000:8000 mcp-server-powershell
```

### Bash Docker Container

```bash
# Build the image
docker build -f Dockerfile.bash -t mcp-server-bash .

# Run the container
docker run -d --name mcp-server-bash -p 8000:8000 mcp-server-bash
```

## Kubernetes Deployment

For production deployments, you can run all MCP servers on Kubernetes with auto-scaling and load balancing.

### Quick Kubernetes Setup

```bash
# Deploy all services to Kubernetes
chmod +x k8s/deploy.sh
./k8s/deploy.sh
```

### Manual Kubernetes Deployment

```bash
# Deploy all MCP servers
kubectl apply -f k8s/python-deployment.yaml
kubectl apply -f k8s/bash-deployment.yaml
kubectl apply -f k8s/powershell-deployment.yaml

# Optional: Setup ingress and auto-scaling
kubectl apply -f k8s/ingress.yaml
kubectl apply -f k8s/hpa.yaml
```

### Access Services

```bash
# Port forward to access locally
kubectl port-forward -n mcp-servers service/mcp-server-python-service 8000:80
kubectl port-forward -n mcp-servers service/mcp-server-bash-service 8001:80
kubectl port-forward -n mcp-servers service/mcp-server-powershell-service 8002:80
```

See `k8s/README.md` for detailed Kubernetes deployment instructions.

## Configuration

All versions use the same RapidAPI key by default. To use your own key:

- **Python**: Modify `RAPIDAPI_KEY` variable in `server.py`
- **PowerShell**: Use `-rapidApiKey` parameter
- **Bash**: Set `RAPIDAPI_KEY` environment variable
- **Docker**: Use environment variables: `-e RAPIDAPI_KEY="your-key"`

## Testing the Server

Once running, test the discovery endpoint:

```bash
curl http://localhost:8000/
```

Test a specific endpoint:

```bash
curl "http://localhost:8000/coles/product-search/?q=milk"
```
