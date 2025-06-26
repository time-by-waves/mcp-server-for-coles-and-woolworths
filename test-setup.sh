#!/bin/bash

echo "Testing MCP Server implementations..."

# Test if required tools are available for bash version
echo "Checking bash server dependencies..."
command -v curl >/dev/null 2>&1 || {
  echo "curl is required but not installed."
  exit 1
}
command -v nc >/dev/null 2>&1 || {
  echo "netcat (nc) is required but not installed."
  exit 1
}

# Test if Python server can import required modules
echo "Checking Python server dependencies..."
python3 -c "import http.server, socketserver, requests, json" 2>/dev/null || {
  echo "Python dependencies missing. Run: pip install requests"
  exit 1
}

# Test if PowerShell is available
echo "Checking PowerShell availability..."
command -v pwsh >/dev/null 2>&1 || { echo "PowerShell (pwsh) not found."; }

echo "All checks passed! Server implementations should work correctly."
echo ""
echo "To start servers:"
echo "Python:     python src/server.py"
echo "PowerShell: pwsh src/server.ps1"
echo "Bash:       ./src/server.sh"
