# ManageVM
README: [English](https://github.com/wellsluo/ManageVM/blob/master/README.md) | [中文](https://github.com/wellsluo/ManageVM/blob/master/README-CN.md)

PowerShell script to manage Hyper-V Virtual Machines based on JSON configuration file.

##Motivation

When I was preparing a demo lab with 10 virtual machines in 20+ physical Hyper-V physical machines, I need to create new virtual machines with same configuration, export, import to other hosts. I felt very boring to do it by clicking mouse button in Hyper-V console. So UI is not good way to do this job.  Automation is definitely the way to manage the virtual machines in large scale.  


##Objectives

Using script to create, export, import or remove multiple virtual machines with same configuration, administrator only needs to setup the configuration file, and then run the script. 

#License

This project is licensed under the MIT License - see the LICENSE file for details.

##Features

Script will use a term "Project" as the entry folder name to save files of all virtual machines. Each virtual machine will be named begin a prefix, the folder name is the same as virtual machine name.  These settings are included in JSON configuration file. Following settings can be set in configuration file:

- Project name
- Virtual machine type (if it is virtual host with nested virtualization or not)
- OS disk template
- Virtual machine number
- Virtual machine name prefix
- Virtual machine generation
- Power on or not after creating
- Network adapter settings
- Hardware (CPU, memory, data disk)


Manage Virtual Machine features: 
- Create New Virtual Machine 
	- Generation 1 and 2.
	- Check OS disk partition type (GUID or MBR).
	- Create internal virtual network switch if not existed.
	- Update existed virtual machine configuration with same name.
	- Attach OS disk based on VHD(X) template.
	- Attach data disks to SCSI controller (up to 63 disks). 
	- Create virtual network adapters and attach to switch.
	- Enable nested VM if necessary. 
- Export existed Virtual Machines
	- Export virtual machines based on JSON configuration file.
- Import Virtual Machines
	- Import virtual machines under one project folder if destination folder is provided.
	- Register virtual machines under one project folder if no destination folder. 
	- Ignore virtual machine configuration file (.VMCX) under snapshot folder.
- Remove Virtual Machines (Forcefully to remove folders)
	- Remove virtual machines based on JSON configuration file.
	- Remove all virtual machines in Hyper-V host.
	- Shutdown virtual machine if it is running and then remove.
	- Remove files and folders with "-ForceFully" switch

Hyper-V role installation state checking.

PowerShell console administrative mode checking.
 
##Supportability
 
###System Requirements
You can run the script on following OS versions and PowerShell version:
- Windows Server 2016
- Windows 10
- PowerShell 4 or above 

##Usage
Put the script and all other files under a folder. Run PowerShell command window in "Elevated" mode. Then go to the folder to run it. 

###EXAMPLE

```PowerShell
    .\Manage-VM.PS1 
```

Create new virtual machines based on default configuration file Manage-VM.Setting.JSON. 

###EXAMPLE

```PowerShell
    .\Manage-VM.PS1 -VMCF .\Manage-VM.Settings.ProjectAlpha.JSON 
```

Create new virtual machines based on configuration file Manage-VM.Settings.ProjectAlpha.JSON.

###EXAMPLE

```PowerShell
    .\Manage-VM.PS1 -Export -ExportDestinationPath V:\VM\Exported 
```

Export the virtual machines to folder V:\VM\Exported. VM names are provided in Manage-VM.Setting.JSON.   Folder name will be the project name in configuration file.

###EXAMPLE

```PowerShell
    .\Manage-VM.PS1 -ForceRemoval -VMCF .\Manage-VM.Settings.ProjectAlpha.JSON  
```

Remove virtual machines based on information of configuration file Manage-VM.Settings.ProjectAlpha.JSON.


###EXAMPLE

```PowerShell
    .\Manage-VM.PS1 -Import -ImportSourcePath V:\VM\Exported\ProjectAlpha -ImportDestinationPath V:\VM
```

Import virtual machines in Copy mode.


###EXAMPLE

```PowerShell
    .\Manage-VM.PS1 -Import -ImportSourcePath V:\VM\ProjectAlpha
```
Import virtual machines in Register mode.


##Help
The script aligns with standard PowerShell help format. To get the help of the script, just run command:  

```PowerShell

Help .\Manage-VM.PS1 -Detailed
 
```

##Dependency

###Deploy-VHD.ps1
The script depends on the script 'Deploy-VHD.ps1' which is from my another repository. It is used to create un-attend files and put in to the OS disk. 

'Deploy-VHD.ps1' version 2.0.100.Main.20170218.1015.0.Release is included in this repository. 

Please refer to: https://github.com/wellsluo/DeployVHD


###Enable-NestedVm.ps1
The script 'Enable-NestedVm.ps1" is used to enable nested virtualization feature of Hyper-V.  

Please refer following blog for detail:
[Windows Insider Preview: Nested Virtualization](https://blogs.technet.microsoft.com/virtualization/2015/10/13/windows-insider-preview-nested-virtualization/)
