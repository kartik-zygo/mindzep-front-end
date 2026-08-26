# 1. Read Postman requests
if (-not (Test-Path "analysis_postman_requests.txt")) {
    Write-Host "Error: analysis_postman_requests.txt not found"
    exit 1
}
$postmanLines = Get-Content "analysis_postman_requests.txt" | Select-Object -Skip 2

# 2. Parse api_endpoints.dart
$endpointsFile = "lib/core/network/api_endpoints.dart"
$endpointMap = @{} 
function Normalize-Path($path) {
    if ($null -eq $path) { return "" }
    $p = $path.ToLower().Split('?')[0]
    $p = $p -replace '\{\{[^}]+\}\}', '{}'
    $p = $p -replace '\$[^/ \n\r]+', '{}'
    $p = $p -replace '\{[^}]+\}', '{}'
    if ($p -notmatch '^/') { $p = "/" + $p }
    return $p
}

if (Test-Path $endpointsFile) {
    $content = Get-Content $endpointsFile -Raw
    $matches = [regex]::Matches($content, 'static (?:const )?String (\w+)(?:\s*\([^)]*\))?\s*(?:=>|=)\s*''([^'']+)''')
    foreach ($m in $matches) {
        $symbol = $m.Groups[1].Value
        $path = $m.Groups[2].Value
        $norm = Normalize-Path $path
        $endpointMap[$norm] = $symbol
    }
}

# 3. Read usage
$usedSymbols = @{}
if (Test-Path "analysis_frontend_endpoint_usage.txt") {
    Get-Content "analysis_frontend_endpoint_usage.txt" | ForEach-Object {
        if ($_ -match 'ApiEndpoints\.(\w+)') { $usedSymbols[$matches[1]] = $true }
    }
}

# 4-6. Process
$results = New-Object System.Collections.Generic.List[PSObject]
foreach ($line in $postmanLines) {
    if ([string]::IsNullOrWhiteSpace($line) -or $line -match '^\-+') { continue }
    $parts = $line.Split('|') | ForEach-Object { $_.Trim() }
    if ($parts.Count -lt 3) { continue }
    
    $method = $parts[0]; $path = $parts[1]; $name = $parts[2]
    $normPath = Normalize-Path $path
    $matchedSymbol = "-"
    if ($endpointMap.ContainsKey($normPath)) { $matchedSymbol = $endpointMap[$normPath] }

    $status = "Missing in Frontend"
    if ($path.StartsWith("/webhooks/")) { $status = "Backend Webhook (N/A Frontend)" }
    elseif ($matchedSymbol -ne "-") {
        $status = if ($usedSymbols.ContainsKey($matchedSymbol)) { "Implemented (Repository)" } else { "Defined Only" }
    }

    $results.Add([PSCustomObject]@{Name=$name; Method=$method; Path=$path; Symbol=$matchedSymbol; Status=$status})
}

# 7-8. Output
$mdLines = @("| Request Name | Method | Path | Matched Endpoint | Status |", "| --- | --- | --- | --- | --- |")
foreach ($r in $results) { $mdLines += "| $($r.Name) | $($r.Method) | $($r.Path) | $($r.Symbol) | $($r.Status) |" }
$mdLines | Out-File -FilePath "analysis_postman_compliance_matrix.md" -Encoding utf8
Write-Host "Postman Compliance Matrix generated."
$results | Group-Object Status | Select-Object Name, Count | Format-Table
Get-Content "analysis_postman_compliance_matrix.md" -TotalCount 20
