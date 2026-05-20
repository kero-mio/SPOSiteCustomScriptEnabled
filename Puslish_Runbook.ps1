# Azure Cloud ShellのPowerShellで実行します。

$resourceGroupName = "AutomationSample" # Azureのリソースグループ名
$automationAccountName = "SPOCustomScript" # 作成したAutomationアカウント名
$runbookName = "SPOCustomScript51"　# 作成したRunbook名

Publish-AzAutomationRunbook `
  -ResourceGroupName $resourceGroupName `
  -AutomationAccountName $automationAccountName `
  -Name $runbookName
