# SPOSiteCustomScriptEnabled
SharePoint Online のサイトに対するカスタムスクリプト有効化（Azure Automation)

## Source Code
- Publish_Runbook.ps1
  <details>作成したRunbookを公開したい場合、Azure Portal ではUI操作が鈍いため、Azure Cloud Shell からRunbookをすぐに公開したい場合に使用します</details> 
- SPOCustomScript51.ps1
  <details>SharePoint Online Management Shell でSharePoint Onlineの特定サイトのカスタムスクリプトを有効化したい場合に使用します</details>
- SPOCustomScript72.ps1
  <details>PnP.PowerShellで、でSharePoint Onlineの特定サイトのカスタムスクリプトを有効化したい場合に使用します</details>

## 準備
 Azure AutomationのRunbookで、上記PowerShellを実行する場合は、下記を用意してください

- 
