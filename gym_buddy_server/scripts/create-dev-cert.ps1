param(
  [Parameter(Mandatory = $true)]
  [string] $HostName,

  [string] $CertDir = "certs",
  [string] $PfxPassword = "gymbuddy-dev"
)

$ErrorActionPreference = "Stop"

if ($IsWindows -eq $false) {
  throw "This script uses Windows certificate cmdlets. Use OpenSSL on non-Windows systems."
}

$resolvedCertDir = Join-Path (Get-Location) $CertDir
New-Item -ItemType Directory -Force -Path $resolvedCertDir | Out-Null

$caSubject = "CN=GymBuddy Dev CA"
$serverSubject = "CN=$HostName"
$now = Get-Date
$caCertPath = Join-Path $resolvedCertDir "gymbuddy-dev-ca.cer"
$caCrtPath = Join-Path $resolvedCertDir "gymbuddy-dev-ca.crt"
$serverPfxPath = Join-Path $resolvedCertDir "server.pfx"
$appDebugRawCertDir = Join-Path (Get-Location) "../gym_buddy_app/android/app/src/debug/res/raw"
$appDebugRawCertPath = Join-Path $appDebugRawCertDir "gymbuddy_dev_ca.cer"

$existingCa = Get-ChildItem Cert:\CurrentUser\My |
  Where-Object { $_.Subject -eq $caSubject } |
  Where-Object { $_.Extensions | Where-Object { $_.Oid.Value -eq "2.5.29.19" } } |
  Sort-Object NotAfter -Descending |
  Select-Object -First 1

if ($null -eq $existingCa) {
  $existingCa = New-SelfSignedCertificate `
    -Type Custom `
    -Subject $caSubject `
    -KeyAlgorithm RSA `
    -KeyLength 2048 `
    -HashAlgorithm SHA256 `
    -KeyExportPolicy Exportable `
    -KeyUsage CertSign, CRLSign, DigitalSignature `
    -TextExtension @(
      "2.5.29.19={critical}{text}ca=1&pathlength=1"
    ) `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -NotAfter $now.AddYears(5)
}

$ip = $null
$isIp = [System.Net.IPAddress]::TryParse($HostName, [ref] $ip)
$sanEntry = if ($isIp) { "IPAddress=$HostName" } else { "DNS=$HostName" }

$serverCert = New-SelfSignedCertificate `
  -Type Custom `
  -Subject $serverSubject `
  -Signer $existingCa `
  -KeyAlgorithm RSA `
  -KeyLength 2048 `
  -HashAlgorithm SHA256 `
  -KeyExportPolicy Exportable `
  -KeyUsage DigitalSignature, KeyEncipherment `
  -TextExtension @(
    "2.5.29.17={text}$sanEntry",
    "2.5.29.37={text}1.3.6.1.5.5.7.3.1"
  ) `
  -CertStoreLocation "Cert:\CurrentUser\My" `
  -NotAfter $now.AddYears(1)

$securePassword = ConvertTo-SecureString $PfxPassword -AsPlainText -Force

Export-Certificate `
  -Cert $existingCa `
  -FilePath $caCertPath `
  -Force | Out-Null

Copy-Item -LiteralPath $caCertPath -Destination $caCrtPath -Force
New-Item -ItemType Directory -Force -Path $appDebugRawCertDir | Out-Null
Copy-Item -LiteralPath $caCertPath -Destination $appDebugRawCertPath -Force

Export-PfxCertificate `
  -Cert $serverCert `
  -FilePath $serverPfxPath `
  -Password $securePassword `
  -Force | Out-Null

Write-Host "Created dev CA: $caCertPath"
Write-Host "Created Android-friendly CA copy: $caCrtPath"
Write-Host "Synced debug app CA resource: $appDebugRawCertPath"
Write-Host "Created server PFX: $serverPfxPath"
Write-Host ""
Write-Host "Backend env:"
Write-Host "`$env:HOST=`"0.0.0.0`""
Write-Host "`$env:PORT=`"5000`""
Write-Host "`$env:HTTPS_ENABLED=`"true`""
Write-Host "`$env:HTTPS_PFX_PATH=`"$CertDir/server.pfx`""
Write-Host "`$env:HTTPS_PFX_PASSPHRASE=`"$PfxPassword`""
Write-Host ""
Write-Host "Install this CA on your Android device:"
Write-Host $caCrtPath
