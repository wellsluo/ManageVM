
Cls

Write-Host "Create VM for domain controller..."
.\Manage-VM.PS1 -VMCF Sample.Manage-VM.Settings.DomainController.JSON -Verbose

Write-Host "Create VM for SDS..."
.\Manage-VM.PS1 -VMCF Sample.Manage-VM.Settings.S2D.JSON -Verbose

Write-Host "Create VM for SDN..."
.\Manage-VM.PS1 -VMCF Sample.Manage-VM.Settings.SDN.JSON -Verbose

Write-Host "Create desktop machine for maangement..."
.\Manage-VM.PS1 -VMCF Sample.Manage-VM.Settings.Client.JSON -Verbose