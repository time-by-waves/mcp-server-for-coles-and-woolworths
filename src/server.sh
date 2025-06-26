#!/bin/bash

# Configuration
PORT=${PORT:-8000}
RAPIDAPI_KEY=${RAPIDAPI_KEY:-"SIGN_UP_FREE_AND_SUBSCRIBE_TO_BOTH_APIS"}

# Graceful shutdown handler
cleanup() {
  echo "Shutting down server gracefully..."
  if [[ -n $server_pid ]]; then
    kill $server_pid 2>/dev/null
  fi
  exit 0
}

trap cleanup SIGINT SIGTERM

# Function to handle HTTP requests
handle_request() {
  local method="$1"
  local path="$2"
  local query="$3"

  echo "Processing: $method $path $query" >&2

  # Discovery endpoint
  if [[ "$path" == "/" ]]; then
    cat <<EOF
HTTP/1.1 200 OK
Content-Type: application/json
Connection: close

{"message":"Welcome to MCP Server","endpoints":["/coles/price-changes/","/coles/product-search/","/woolworths/price-changes/","/woolworths/barcode-search/*","/woolworths/product-search/"]}
EOF
    return
  fi

  # Route to upstream APIs
  local upstream_url=""
  local rapidapi_host=""

  case "$path" in
  "/coles/price-changes/")
    rapidapi_host="coles-product-price-api.p.rapidapi.com"
    upstream_url="https://${rapidapi_host}/coles/price-changes/"
    ;;
  "/coles/product-search/")
    rapidapi_host="coles-product-price-api.p.rapidapi.com"
    upstream_url="https://${rapidapi_host}/coles/product-search/"
    ;;
  "/woolworths/price-changes/")
    rapidapi_host="woolworths-products-api.p.rapidapi.com"
    upstream_url="https://${rapidapi_host}/woolworths/price-changes/"
    ;;
  "/woolworths/barcode-search/"*)
    rapidapi_host="woolworths-products-api.p.rapidapi.com"
    barcode=$(echo "$path" | sed 's|/woolworths/barcode-search/||')
    upstream_url="https://${rapidapi_host}/woolworths/barcode-search/${barcode}"
    ;;
  "/woolworths/product-search/")
    rapidapi_host="woolworths-products-api.p.rapidapi.com"
    upstream_url="https://${rapidapi_host}/woolworths/product-search/"
    ;;
  *)
    cat <<EOF
HTTP/1.1 404 Not Found
Content-Type: text/plain
Connection: close

Not Found
EOF
    return
    ;;
  esac

  # Forward request to upstream API
  if [[ -n "$upstream_url" ]]; then
    if [[ -n "$query" ]]; then
      upstream_url="${upstream_url}?${query}"
    fi

    response=$(curl -s -w "HTTPSTATUS:%{http_code}" \
      -H "X-Rapidapi-Key: $RAPIDAPI_KEY" \
      -H "X-Rapidapi-Host: $rapidapi_host" \
      "$upstream_url")

    http_code=$(echo "$response" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
    response_body=$(echo "$response" | sed 's/HTTPSTATUS:[0-9]*$//')

    if [[ "$http_code" == "200" ]]; then
      cat <<EOF
HTTP/1.1 200 OK
Content-Type: application/json
Connection: close

$response_body
EOF
    else
      cat <<EOF
HTTP/1.1 $http_code Error
Content-Type: application/json
Connection: close

$response_body
EOF
    fi
  fi
}

# Start HTTP server using netcat
echo "Starting MCP server on http://localhost:$PORT"
echo "Press Ctrl+C to stop the server"

while true; do
  # Listen for connections and process requests
  {
    while read -r line; do
      # Parse the HTTP request line
      if [[ "$line" =~ ^(GET|POST|PUT|DELETE|PATCH|HEAD|OPTIONS)[[:space:]]+([^[:space:]?]*)\??([^[:space:]]*)[[:space:]]+HTTP/.*$ ]]; then
        method="${BASH_REMATCH[1]}"
        path="${BASH_REMATCH[2]}"
        query="${BASH_REMATCH[3]}"

        # Read headers until empty line
        while read -r header_line && [[ "$header_line" != $'\r' ]] && [[ -n "$header_line" ]]; do
          : # Skip headers for now
        done

        # Handle the request
        handle_request "$method" "$path" "$query"
        break
      fi
    done
  } | nc -l -p "$PORT" -q 1
done
