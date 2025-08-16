Param(
  [string]$OutZip = "nyc_taxi_ops_202506_bundle_v2.zip"
)
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$src = Join-Path $root "NYC Taxi Ops (Jun 2025)"
if (Test-Path $OutZip) { Remove-Item $OutZip -Force }
Compress-Archive -Path (Join-Path $src "*") -DestinationPath $OutZip
Write-Host "Created $OutZip"
