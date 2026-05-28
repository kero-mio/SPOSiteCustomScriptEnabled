# SharePoint Online の特定サイトに対する、カスタムスクリプトを継続的に有効化する（Azure Automation利用)
- SharePoint Online のサイトに対するカスタムスクリプト有効化を、Azure AutomationとPowerShellを使って行うものです。
- Azure Automationアカウント内で、スケジュール実行設定も可能です
- ランタイムに、PowerShell 7.2を利用する場合は、SPOCustomScript72.ps1を、PowerShell 5.1を利用する場合は、SPOCustomScript51.ps1の利用を推奨します
- なお、SPOCustomScript72.ps1(PowerShell 7.2)の場合は、PnP.PowerShellを利用しています。
- 一方、SPOCustomScript51.ps1(PowerShell 5.2)の場合は、SharePoint Online Management Shell を利用しています

## Source Code
- Publish_Runbook.ps1
  <details>作成したRunbookを公開したい場合、Azure Portal ではUI操作が鈍いため、Azure Cloud Shell からRunbookをすぐに公開したい場合に使用します</details> 
- SPOCustomScript51.ps1
  <details>SharePoint Online Management Shell でSharePoint Onlineの特定サイトのカスタムスクリプトを有効化したい場合に使用します</details>
- SPOCustomScript72.ps1
  <details>PnP.PowerShellで、でSharePoint Onlineの特定サイトのカスタムスクリプトを有効化したい場合に使用します</details>

## 準備
  Azure AutomationのRunbookで、上記PowerShellを実行する場合は、下記を用意してください
  
### Azure Automationアカウントの設定で、変数を追加します
+ ClientId
  <details>
    Entra ID のアプリ登録したクライアントIDを設定してください。
    なお、Entra ID のアプリ登録は、下記のように設定してください

    
    - 1.証明書を作成する
      
      まず、自分のPCのPowerShellで自己証明書を作成します。(作成されるファイルは*.cerと*.pfxの2つです。)
    
      ```powershell: 自己証明書を作成する
      $certName = "SPOCustomScriptAutomation"
      $certPassword = Read-Host "PFX password" -AsSecureString
      
      $cert = New-SelfSignedCertificate `
        -Subject "CN=$certName" `
        -CertStoreLocation "Cert:\CurrentUser\My" `
        -KeyExportPolicy Exportable `
        -KeySpec Signature `
        -KeyLength 2048 `
        -NotAfter (Get-Date).AddYears(2)
      
      Export-Certificate `
        -Cert $cert `
        -FilePath ".\$certName.cer"
      
      Export-PfxCertificate `
        -Cert $cert `
        -FilePath ".\$certName.pfx" `
        -Password $certPassword
      ```
  
    - 2.Entra IDでアプリ登録する
      Azure Portalで以下を実施します。
      <pre>
        Microsoft Entra ID
        → アプリの登録
        → 新規登録
      </pre>
      
    - 3.アプリに証明書を登録する
      Entra ID で登録したアプリに対し、証明書(*.cer)を登録します
      <pre>
        証明書とシークレット
        → 証明書
        → 証明書のアップロード
      </pre>
      
    - 4.アプリにSharePoint権限を付与する
      アプリ登録で以下を設定します。
      <pre>
        APIのアクセス許可
        → アクセス許可の追加
        → SharePoint
        → アプリケーションの許可
        → Sites.FullControl.All
        → 管理者の同意を付与
      </pre>
      
      なお、Sites.FullControl.Allでは、権限が強すぎるため、Sites.Selected を付与し、Graph Explorer等で、特定サイトに対するFullControl権限を付与しても構いません。
      ```powershell: Sites.SelectedでAPIアクセス許可設定した後、特定サイトにFullControlを与える方法
      $targetAppClientId = "[Sites.FullControl.All]のAPIアクセス許可があるEntra IDアプリのクライアントID"
      $targetAppName     = "SPOCustomScript"
      $siteUrlHost       = "[テナント名].sharepoint.com"
      $sitePath          = "/sites/[対象サイトコレクション]"
      
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
      ```
      
  </details>
+ SiteUrl
  <details>SharePoint Onlineにあるサイトで、カスタムスクリプトを有効化したいサイトのURLを指定してください</details>
+ SPOAppCertBase64
  <details>
    SharePoint Onlineに接続する際に準備した自己証明書(秘密鍵が含まれているpfx)のBase64でエンコードしたものを設定してください。下記にpfxをBase64化するサンプルを記載します。
    Windows PC+PowerShell v5.1以上で実行し、クリップボードに張り付けられた内容をそのままペーストして定義してください
    
    ```powershell: 自己証明書のBase64化
    $pfxPath = "C:\work\SPOCustomScriptAutomation.pfx"
    $base64 = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($pfxPath))
    $base64 | Set-Clipboard
    ```
    
  </details>
+ SPOAppCertPassword
  <details>SharePoint Onlineに接続する際に準備した自己証明書(秘密鍵が含まれているpfx)のパスワードを設定してください</details>
+ Tenant
  <details>[テナント名].onmicrosoft.com　を設定してください</details>
+ TenantAdminUrl
  <details>SharePoint Onlineの管理センターURL（ルート）を指定してください</details>
+ TenantId
  <details>AzureのテナントIDを設定してください</details>

### 自己証明書(pfx)をAzure Automationに登録
  Azure Automation側で、証明書を設定します。
  証明書は、[ClientId] - [1.証明書を作成する] で作成した*.pfxの証明書をAzure Automationアカウントに対し、アップロードします
  <pre>
  作成したAutomationアカウント
    → 共有リソース
    → 証明書
    → 証明書の追加(*.pfx)
  </pre>

### Automationアカウントに、モジュール追加
Automationアカウント - [共有リソース] - [モジュール]に下記を追加してください

- PnP.PowerShell モジュールバージョン:2.12.0 ランタイムバージョン:7.2
  
  [PnP.PowerShell 2.12.0](https://www.powershellgallery.com/packages/PnP.PowerShell/2.12.0)

- SharePoint Online Management Shell モジュールバージョン:16.0.27215.12000 または 16.0.27215.12001　ランタイムバージョン: 5.1 or 7.2
  
  [SharePoint Online Management Shell](https://www.powershellgallery.com/packages/Microsoft.Online.SharePoint.PowerShell/16.0.26413.12010)


※うまくデプロイできない場合は、Manual Download で、Nuget Package版をダウンロードし、拡張子を*.zipに変更の上、手動でAutomationアカウントにアップロードしてください
  
### Runbookを作成と設定
- [編集]メニューから、[VS Codeで編集] または、[ポータルで編集]　を選択し、当レポジトリにある、[SPOCustomScriptXX.ps1]のコードを張り付けてください
- [テスト ウィンドウ] を起動し、 [開始]ボタンで動作検証を実施してください
- 問題なければ、Runbookを公開します。なお、Azure PortalからRunbookを公開すると、GUI反応が悪いため、即時公開する場合は、Azure Cloud Shell を使い、Publish_Runbook.ps1を手動で実行することで、Runbookを即時公開できます。

### 上記でわかりづらい方へ
 Plus Cloud Tech Blog [https://blog.platic.jp/20260528/] にて、補足を解説していますので、ご確認ください
