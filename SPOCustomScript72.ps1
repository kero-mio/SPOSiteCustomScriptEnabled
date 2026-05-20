$ErrorActionPreference = "Stop"

$SiteUrl = Get-AutomationVariable -Name 'SiteUrl'
$TenantAdminUrl = Get-AutomationVariable -Name 'TenantAdminUrl'

# アプリ登録の「アプリケーション、クライアント ID」
$ClientId = Get-AutomationVariable -Name 'ClientId'

# Entra ID のプライマリドメインを指定
# 例: ****.onmicrosoft.com
# 実際の初期ドメインが違う場合は、Entra ID の概要画面で確認して差し替えてください
$Tenant = Get-AutomationVariable -Name 'Tenant'

Write-Output "Start: $(Get-Date -Format o)"
Write-Output "SiteUrl: $SiteUrl"

Import-Module PnP.PowerShell -ErrorAction Stop

$CertBase64 = Get-AutomationVariable -Name "SPOAppCertBase64"
$CertPasswordPlain = Get-AutomationVariable -Name "SPOAppCertPassword"

if ([string]::IsNullOrWhiteSpace($CertBase64)) {
    throw "Automation variable 'SPOAppCertBase64' is empty."
}

if ([string]::IsNullOrWhiteSpace($CertPasswordPlain)) {
    throw "Automation variable 'SPOAppCertPassword' is empty."
}

$CertPassword = ConvertTo-SecureString $CertPasswordPlain -AsPlainText -Force

Connect-PnPOnline `
    -Url $SiteUrl `
    -ClientId $ClientId `
    -Tenant $Tenant `
    -CertificateBase64Encoded $CertBase64 `
    -CertificatePassword $CertPassword `
    -TenantAdminUrl $TenantAdminUrl

Write-Output "Connected to SharePoint by PnP.PowerShell."

Set-PnPSite -NoScriptSite $false

Write-Output "Custom script enabled for site."
Write-Output "End: $(Get-Date -Format o)"
