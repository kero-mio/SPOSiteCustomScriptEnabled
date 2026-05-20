#☆特定サイトのみFullControlのAPIアクセス許可を行う

Connect-MgGraph -Scopes "Sites.FullControl.All"

$targetAppClientId = "f5092184-ac6b-4564-a7c2-a0766922bba9"
$targetAppName     = "SPOCustomScript"
$siteUrlHost       = "psychopathconsulting.sharepoint.com"
$sitePath          = "/sites/edamitsu"

$site = Invoke-MgGraphRequest `
  -Method GET `
  -Uri "https://graph.microsoft.com/v1.0/sites/$siteUrlHost`:$sitePath`:"

$body = @{
    roles = @("fullcontrol")
    grantedToIdentities = @(
        @{
            application = @{
                id = $targetAppClientId
                displayName = $targetAppName
            }
        }
    )
} | ConvertTo-Json -Depth 10

Invoke-MgGraphRequest `
  -Method POST `
  -Uri "https://graph.microsoft.com/v1.0/sites/$($site.id)/permissions" `
  -Body $body `
  -ContentType "application/json"