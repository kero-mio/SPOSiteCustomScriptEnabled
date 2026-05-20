# Azure Cloud ShellのPowerShellで実行します。

$resourceGroupName = "AutomationSample"
$automationAccountName = "SPOCustomScript"
$runbookName = "SPOCustomScript51"

Publish-AzAutomationRunbook `
  -ResourceGroupName $resourceGroupName `
  -AutomationAccountName $automationAccountName `
  -Name $runbookName