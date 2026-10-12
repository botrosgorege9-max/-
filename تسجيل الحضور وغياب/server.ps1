$port = 8080
$baseDir = $PSScriptRoot
if (-not $baseDir) { $baseDir = (Get-Location).Path }

$crlf = [string][char]13 + [string][char]10

# Get local IP
$ipObj = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | 
    Where-Object { $_.InterfaceAlias -notmatch 'Loopback|vEthernet|VMnet' -and $_.IPAddress -notmatch '^169\.254\.' } | 
    Select-Object -First 1

$lanIP = if ($ipObj) { $ipObj.IPAddress } else { "192.168.1.14" }

$localUrl = "http://localhost:" + $port + "/"
$mobileUrl = "http://" + $lanIP + ":" + $port + "/"

$listener = New-Object System.Net.Sockets.TcpListener ([System.Net.IPAddress]::Any), $port

try {
    $listener.Start()
    Write-Host ""
    Write-Host "=================================================================" -ForegroundColor Cyan
    Write-Host "   St. Anthony Church Attendance System (QR)" -ForegroundColor Yellow
    Write-Host "=================================================================" -ForegroundColor Cyan
    Write-Host " [1] PC Local Link:     $localUrl" -ForegroundColor Green
    Write-Host " [2] Mobile Wi-Fi Link: $mobileUrl" -ForegroundColor Magenta
    Write-Host "-----------------------------------------------------------------" -ForegroundColor Gray
    Write-Host " Open the Mobile link in your phone browser connected to the same Wi-Fi." -ForegroundColor White
    Write-Host " Press Ctrl + C to stop the server." -ForegroundColor Gray
    Write-Host "=================================================================" -ForegroundColor Cyan
    Write-Host ""

    Start-Process $localUrl

    while ($true) {
        $client = $listener.AcceptTcpClient()
        try {
            $stream = $client.GetStream()
            $buffer = New-Object byte[] 4096
            $bytesRead = $stream.Read($buffer, 0, $buffer.Length)
            if ($bytesRead -gt 0) {
                $requestStr = [System.Text.Encoding]::UTF8.GetString($buffer, 0, $bytesRead)
                $firstLine = $requestStr.Split([char]10)[0].Trim()
                $parts = $firstLine.Split(" ")

                if ($parts.Length -ge 2) {
                    $rawPath = $parts[1].Split('?')[0].TrimStart('/')
                    if ([string]::IsNullOrEmpty($rawPath)) {
                        $rawPath = "index.html"
                    }

                    $decodedPath = [System.Uri]::UnescapeDataString($rawPath)
                    $filePath = Join-Path $baseDir $decodedPath

                    if (Test-Path $filePath -PathType Leaf) {
                        $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
                        $mime = "application/octet-stream"
                        if ($ext -eq ".html" -or $ext -eq ".htm") { $mime = "text/html; charset=utf-8" }
                        elseif ($ext -eq ".css") { $mime = "text/css; charset=utf-8" }
                        elseif ($ext -eq ".js") { $mime = "application/javascript; charset=utf-8" }
                        elseif ($ext -eq ".json") { $mime = "application/json; charset=utf-8" }
                        elseif ($ext -eq ".png") { $mime = "image/png" }
                        elseif ($ext -eq ".jpg" -or $ext -eq ".jpeg") { $mime = "image/jpeg" }
                        elseif ($ext -eq ".svg") { $mime = "image/svg+xml" }
                        elseif ($ext -eq ".ico") { $mime = "image/x-icon" }

                        $fileBytes = [System.IO.File]::ReadAllBytes($filePath)
                        $headerStr = "HTTP/1.1 200 OK" + $crlf + "Content-Type: " + $mime + $crlf + "Content-Length: " + $fileBytes.Length + $crlf + "Access-Control-Allow-Origin: *" + $crlf + "Connection: close" + $crlf + $crlf
                        $headerBytes = [System.Text.Encoding]::ASCII.GetBytes($headerStr)

                        $stream.Write($headerBytes, 0, $headerBytes.Length)
                        $stream.Write($fileBytes, 0, $fileBytes.Length)
                        $stream.Flush()
                    } else {
                        $errBody = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found")
                        $errHeader = "HTTP/1.1 404 Not Found" + $crlf + "Content-Type: text/plain; charset=utf-8" + $crlf + "Content-Length: " + $errBody.Length + $crlf + "Connection: close" + $crlf + $crlf
                        $errHBytes = [System.Text.Encoding]::ASCII.GetBytes($errHeader)
                        $stream.Write($errHBytes, 0, $errHBytes.Length)
                        $stream.Write($errBody, 0, $errBody.Length)
                        $stream.Flush()
                    }
                }
            }
        } catch {
        } finally {
            $client.Close()
        }
    }
} catch {
    Write-Host "Server Error: $_" -ForegroundColor Red
} finally {
    if ($listener) { $listener.Stop() }
}
