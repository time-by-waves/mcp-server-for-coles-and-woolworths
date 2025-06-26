param (

  [Parameter(Mandatory = $false)]
  [int]$port = 8000, # Default port

  [Parameter(Mandatory = $false)]
  [string]$rapidApiKey = 'SIGN_UP_FREE_AND_SUBSCRIBE_TO_BOTH_APIS', # Default RapidAPI Key

  [Parameter(Mandatory = $false)]
  [string]$hostPrefix = 'http://localhost' # Default Host Prefix
)

# Define the port to listen on
$prefix = "$( $hostPrefix ):$( $port )/"

# Create and start the HTTP listener
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)

Write-Host "Starting MCP server on $prefix..."
$listener.Start()
Write-Host 'Server started. Press Ctrl+C to stop.'

# Add a handler for graceful shutdown
$onExit = {
  Write-Host 'Stopping server gracefully...'
  if ($listener -and $listener.IsListening) {
    $listener.Stop()
  }
  Write-Host 'Server stopped.'
  exit
}

# Register the handler for Ctrl+C
$null = Register-ObjectEvent -InputObject $Host -EventName 'CancelKeyPress' -Action $onExit

try {
  # Main loop to process incoming requests
  while ($listener.IsListening) {
    # Wait for a request
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response

    $upstreamUrl = $null
    $upstreamHost = $null
    $barcode = $null

    # Route requests based on the path
    switch -Wildcard ($request.Url.AbsolutePath) {
      '/coles/price-changes/' {
        $upstreamHost = 'coles-product-price-api.p.rapidapi.com'
        $upstreamUrl = 'https://{0}{1}' -f $upstreamHost, $request.Url.PathAndQuery
      }
      '/coles/product-search/' {
        $upstreamHost = 'coles-product-price-api.p.rapidapi.com'
        $upstreamUrl = 'https://{0}{1}' -f $upstreamHost, $request.Url.PathAndQuery
      }
      '/woolworths/price-changes/' {
        $upstreamHost = 'woolworths-products-api.p.rapidapi.com'
        $upstreamUrl = 'https://{0}{1}' -f $upstreamHost, $request.Url.PathAndQuery
      }
      '/woolworths/barcode-search/*' {
        $upstreamHost = 'woolworths-products-api.p.rapidapi.com'
        $barcode = $request.Url.Segments[-1]
        $upstreamUrl = 'https://{0}/woolworths/barcode-search/{1}' -f $upstreamHost, $barcode
      }
      '/woolworths/product-search/' {
        $upstreamHost = 'woolworths-products-api.p.rapidapi.com'
        $upstreamUrl = 'https://{0}{1}' -f $upstreamHost, $request.Url.PathAndQuery
      }
      '/' {
        # Add a discovery endpoint at the root path
        $response.StatusCode = 200
        $response.ContentType = 'application/json'
        $discoInfo = @{ 'message' = 'Welcome to MCP Server'; 'endpoints' = @('/coles/price-changes/', '/coles/product-search/', '/woolworths/price-changes/', '/woolworths/barcode-search/*', '/woolworths/product-search/') }
        $buffer = [System.Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject $discoInfo -Depth 10))
        $response.ContentLength64 = $buffer.Length
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
        continue
      }
    }

    if ($upstreamUrl) {
      $headers = @{
        'X-Rapidapi-Key'  = $rapidApiKey
        'X-Rapidapi-Host' = $upstreamHost
      }

      try {
        # Forward the request to the upstream API
        Write-Host ('Forwarding request to: {0}' -f $upstreamUrl)
        $upstreamResponse = Invoke-WebRequest -Uri $upstreamUrl -Method $request.HttpMethod -Headers $headers -UseBasicParsing

        # Write the upstream response back to the client
        $response.StatusCode = $upstreamResponse.StatusCode
        $response.ContentType = $upstreamResponse.Headers['Content-Type']

        $buffer = [System.Text.Encoding]::UTF8.GetBytes($upstreamResponse.Content)
        $response.ContentLength64 = $buffer.Length
        $response.OutputStream.Write($buffer, 0, $buffer.Length)

      } catch {
        # Handle errors from the upstream API
        $errorMessage = "Error fetching data from upstream API: $($_.Exception.Message)"
        Write-Warning $errorMessage
        $response.StatusCode = 500 # Internal Server Error
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($errorMessage)
        $response.ContentLength64 = $buffer.Length
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
      }
    } else {
      # Handle 404 Not Found
      $response.StatusCode = 404
      $buffer = [System.Text.Encoding]::UTF8.GetBytes('Not Found')
      $response.ContentLength64 = $buffer.Length
      $response.OutputStream.Write($buffer, 0, $buffer.Length)
    }

    # Close the response to send it to the client
    $response.Close()
  }
} finally {
  # Stop the listener when the script exits
  Write-Host 'Stopping server...'
  $listener.Stop()
}
