$ErrorActionPreference = "Stop"

$AdminUrl = Get-AutomationVariable -Name 'TenantAdminUrl'
$SiteUrl  = Get-AutomationVariable -Name 'SiteUrl'

# アプリ登録の「アプリケーション、クライアント ID」
$ClientId = Get-AutomationVariable -Name 'ClientId'

# Entra ID の「ディレクトリ、テナント ID」
$TenantId = Get-AutomationVariable -Name 'TenantId'

# PFXをBase64化した文字列
$pfxBase64 = Get-AutomationVariable -Name 'SPOAppCertBase64'

# PFX作成時のパスワード
$pfxPasswordPlain = Get-AutomationVariable -Name 'SPOAppCertPassword'

Write-Output "Start: $(Get-Date -Format o)"
Write-Output "AdminUrl: $AdminUrl"
Write-Output "SiteUrl : $SiteUrl"
Write-Output "ClientId: $ClientId"
Write-Output "TenantId: $TenantId"

Import-Module Microsoft.Online.SharePoint.PowerShell -ErrorAction Stop

if ([string]::IsNullOrWhiteSpace($pfxBase64)) {
    throw "Automation variable 'SPOAppCertBase64' is empty."
}

if ([string]::IsNullOrWhiteSpace($pfxPasswordPlain)) {
    throw "Automation variable 'SPOAppCertPassword' is empty."
}

$pfxPath = Join-Path $env:TEMP "SPOAppCert.pfx"

try {
    # Base64文字列から一時PFXファイルを作成
    [System.IO.File]::WriteAllBytes(
        $pfxPath,
        [Convert]::FromBase64String($pfxBase64)
    )

    Write-Output "Temporary PFX file created: $pfxPath"

    # PFX内容確認
    $checkCert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
    $checkCert.Import(
        $pfxPath,
        $pfxPasswordPlain,
        [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable
    )

    Write-Output "PFX Subject      : $($checkCert.Subject)"
    Write-Output "PFX Thumbprint   : $($checkCert.Thumbprint)"
    Write-Output "PFX HasPrivateKey: $($checkCert.HasPrivateKey)"

    if (-not $checkCert.HasPrivateKey) {
        throw "The PFX file does not have a private key."
    }

    $pfxPassword = ConvertTo-SecureString $pfxPasswordPlain -AsPlainText -Force

    Connect-SPOService `
        -Url $AdminUrl `
        -ClientId $ClientId `
        -TenantId $TenantId `
        -CertificatePath $pfxPath `
        -CertificatePassword $pfxPassword

    Write-Output "Connected to SharePoint Online by Microsoft.Online.SharePoint.PowerShell."

    Set-SPOSite `
        -Identity $SiteUrl `
        -DenyAddAndCustomizePages $false
    
    $site = Get-SPOSite -Identity $SiteUrl
    Write-Output "DenyAddAndCustomizePages: $($site.DenyAddAndCustomizePages)"
    
    if ($site.DenyAddAndCustomizePages -ne "Disabled") {
        throw "Custom script enablement failed. Expected DenyAddAndCustomizePages = Disabled, but actual value is '$($site.DenyAddAndCustomizePages)'."
    }
    
    Write-Output "Custom script enablement verified successfully."
}
finally {
    if (Test-Path $pfxPath) {
        Remove-Item $pfxPath -Force -ErrorAction SilentlyContinue
        Write-Output "Temporary PFX file removed."
    }
}

Write-Output "End: $(Get-Date -Format o)"
