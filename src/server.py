import http.server
import socketserver
import requests
import json
from urllib.parse import urlparse, parse_qs
import signal
import sys

# Your RapidAPI key
RAPIDAPI_KEY = "SIGN_UP_FREE_AND_SUBSCRIBE_TO_BOTH_APIS"


class MCPHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        parsed_path = urlparse(self.path)
        path = parsed_path.path
        query_params = parse_qs(parsed_path.query)

        upstream_url = None
        headers = {
            "X-Rapidapi-Key": RAPIDAPI_KEY,
        }

        # Add a discovery endpoint at the root path
        if path == "/":
            response = {
                "message": "Welcome to MCP Server",
                "endpoints": [
                    "/coles/price-changes/",
                    "/coles/product-search/",
                    "/woolworths/price-changes/",
                    "/woolworths/barcode-search/*",
                    "/woolworths/product-search/",
                ],
            }
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(response).encode())
            return

        if path == "/coles/price-changes/":
            headers["X-Rapidapi-Host"] = "coles-product-price-api.p.rapidapi.com"
            upstream_url = (
                f"https://coles-product-price-api.p.rapidapi.com/coles/price-changes/"
            )
        elif path == "/coles/product-search/":
            headers["X-Rapidapi-Host"] = "coles-product-price-api.p.rapidapi.com"
            upstream_url = (
                f"https://coles-product-price-api.p.rapidapi.com/coles/product-search/"
            )
        elif path == "/woolworths/price-changes/":
            headers["X-Rapidapi-Host"] = "woolworths-products-api.p.rapidapi.com"
            upstream_url = f"https://woolworths-products-api.p.rapidapi.com/woolworths/price-changes/"
        elif path.startswith("/woolworths/barcode-search/"):
            headers["X-Rapidapi-Host"] = "woolworths-products-api.p.rapidapi.com"
            barcode = path.split("/")[-1]
            upstream_url = f"https://woolworths-products-api.p.rapidapi.com/woolworths/barcode-search/{barcode}"
        elif path == "/woolworths/product-search/":
            headers["X-Rapidapi-Host"] = "woolworths-products-api.p.rapidapi.com"
            upstream_url = f"https://woolworths-products-api.p.rapidapi.com/woolworths/product-search/"

        if upstream_url:
            try:
                response = requests.get(
                    upstream_url, headers=headers, params=query_params
                )
                self.send_response(response.status_code)
                for key, value in response.headers.items():
                    self.send_header(key, value)
                self.end_headers()
                self.wfile.write(response.content)
            except requests.exceptions.RequestException as e:
                self.send_error(500, f"Error fetching data from upstream API: {e}")
        else:
            self.send_error(404, "Not Found")


def graceful_shutdown(signal, frame):
    print("\nShutting down server gracefully...")
    sys.exit(0)


signal.signal(signal.SIGINT, graceful_shutdown)

PORT = 8000

with socketserver.TCPServer(("", PORT), MCPHandler) as httpd:
    print(f"Serving at port {PORT}")
    print(f"You can now make requests to http://localhost:{PORT}")
    httpd.serve_forever()
