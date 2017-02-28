# 
# Copyright 2017-Present Wei Luo
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy 
# of this software and associated documentation files (the "Software"), to deal 
# in the Software without restriction, including without limitation the rights 
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
# copies of the Software, and to permit persons to whom the Software is 
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
# SOFTWARE.
# 
# 
# 
# Script to:
#     Manage Virtual Machine
#       .Create New Virtual Machine - Generation 1 and 2
#       .Enable Nested VM
#       .Export existed Virtual Machines
#       .Import Virtual Machines
#       .Remove Virtual Machines (Forcelly to remove folders)
#
# Script can be run at following OS versions with Hyper-V installed:
#     Windows Server 2016
#     Windows Server 2012 R2
#     Windows 10 x64
#
#
#
# SCRIPT_VERSION: 1.0.100.Main.20170228.0228.0
#
#
# 

<#
    .NOTES
        THE SAMPLE SOURCE CODE IS PROVIDED "AS IS", WITH NO WARRANTIES.
        THE SAMPLE SOURCE CODE IS UNDER THE MIT LICENSE.
        Developed by Wei Luo.
            
    .SYNOPSIS
        Manage Virtual Machines. 

    .DESCRIPTION
        This script will create, import, export, remove the multiple Hyper-V virutal machines based on JSON configuration file. 
    
    .PARAMETER New
        Create new virtual machines. The virtual machine configuration is from .Setting.Json file.

    .PARAMETER Export
        Export virtual machines to specific folder. 
    
    .PARAMETER ExportDestinationPath
    	The destination folder that the virtual machines will be exported to. 

    .PARAMETER Import
    	Import virtual machines. There are two modes to import virtual machines: Copy and Register.
        If Destination folder is provided, "Import" is Copy mode, otherwise is Rgister mode. 

        Copy mode:     all related folders and files will be copied to destination folder, and import all virtual machines.
        Register mode: virtual machines will be registered directly in original folder, no folders/files copy.  

    .PARAMETER ImportSourcePath
    	Provide the source path of the virtual machines which will be imported. 

    .PARAMETER ImportDestinationPath
        Provide the destination path of the virtual machines which will be imported.
        The Import is Copy mode with this parametner.

    .PARAMETER Remove
        Remove virtual machines from a project folder. The project name is defined in Settings.JSON file.
        The files and folder of the VM will not be removed with this parameter only.
    
    .PARAMETER RemoveAll
        Remove all virtual machines in the host. The files and folder of the VM will not be removed with this parameter only.

    .PARAMETER ForceRemoval
        Remove virtual machines and the files/folder of the VM even the virutal machine is running. 
        The parameter must be provided with "Remove" or "RemoveAll".

    .PARAMETER VMConfigurationFile
        The path of the configuration file, which includes the virtual machine related inforamtion. 
        Default setting file name is Manage-VM.Setting.JSON if it is not provided from command line. 
        
    .EXAMPLE
        Manage-VM.PS1

        Create new virtual machines based on default configuration file Manage-VM.Setting.JSON.

    .EXAMPLE
        Manage-VM.PS1 -VMCF .\Manage-VM.Settings.ProjectAlpha.JSON 

        Create new virtual machines based on configuration file Manage-VM.Settings.ProjectAlpha.JSON
        
    .EXAMPLE
        Manage-VM.PS1 -Export -ExportDestinationPath V:\VM\Exported
        
        Export the virtual machines to folder V:\VM\Exported. VM names are provided in Manage-VM.Setting.JSON.
        Folder name will be the project name in configuration file.

    .EXAMPLE
        Manage-VM.PS1 -ForceRemoval -VMCF .\Manage-VM.Settings.ProjectAlpha.JSON

        Remove virtual machines based on information of configuration file Manage-VM.Settings.ProjectAlpha.JSON.

    .EXAMPLE
        Manage-VM.PS1 -Import -ImportSourcePath V:\VM\Exported\ProjectAlpha -ImportDestinationPath V:\VM

        Import virtual machines in Copy mode.

    .EXAMPLE
        Manage-VM.PS1 -Import -ImportSourcePath V:\VM\ProjectAlpha

        Import virtual machines in Register mode.
        
    .LINK 
        https://github.com/wellsluo/ManageVM

    .INPUTS
    .OUTPUTS
        
  #>


[CmdletBinding(DefaultParametersetName="NEW")]
Param(
    [Parameter(Mandatory=$False, ParameterSetName='NEW')]
    [Alias("N")]
    [switch]$New,

    
    [Parameter(Mandatory=$True, ParameterSetName='EXPORT')]
    [Alias("E")]
    [switch]$Export, 
    
    [Parameter(Mandatory=$True, ParameterSetName='EXPORT')]
    [Alias("EDP")]
    [string]$ExportDestinationPath, 


    [Parameter(Mandatory=$True, ParameterSetName='IMPORT')]
    [Alias("I")]
    [switch]$Import,

    [Parameter(Mandatory=$True, ParameterSetName='IMPORT')]
    [Alias("ISP")]
    [ValidateScript({Test-Path $_})]
    [string]$ImportSourcePath,

    [Parameter(Mandatory=$False, ParameterSetName='IMPORT')]
    [Alias("IDP")]
    [string]$ImportDestinationPath,

    [Parameter(Mandatory=$True, ParameterSetName='REMOVE')]
    [Alias("R")]
    [switch]$Remove,

    [Parameter(Mandatory=$True, ParameterSetName='REMOVEALL')]
    [Alias("RA")]
    [switch]$RemoveAll,

    [Parameter(Mandatory=$False, ParameterSetName='REMOVE')]
    [Parameter(Mandatory=$False, ParameterSetName='REMOVEALL')]
    [Alias("FR")]
    [switch]$ForceRemoval,


    [Parameter(Mandatory=$False, ParameterSetName='NEW')]
    [Parameter(Mandatory=$False, ParameterSetName='REMOVE')]
    [Parameter(Mandatory=$False, ParameterSetName='IMPORT')]
    [Parameter(Mandatory=$False, ParameterSetName='EXPORT')]  
    [ValidateScript({Test-Path $_ -PathType 'Leaf'})]
    [Alias("VMCF")]
    [string]$VMConfigurationFile = "Manage-VM.Settings.JSON"
    )


#region CONSTANT



#declare constants
Set-Variable -Name SCRIPT_VERSION -Value "1.0.100.Main.20170228.0228.0" -Option Constant
Set-Variable -Name SCRIPT_NAME -Value $MyInvocation.MyCommand  -Option Constant


#endregion CONSTANT


#region CODE

#region Functions

##########################################################################################
#Get local host name
Function Get-LocalHostName
{
    return [System.Net.Dns]::GetHostName()

}


#Write script message / log
Function Write-ScriptMessage 
{ # Function to make the Write-ScriptMessage "Trace" output a bit prettier. 
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $false)]
        [ValidateSet("Info","Warn", "Err", "Trace")]
        [ValidateNotNullOrEmpty()]
        [string]$category,

        [Parameter(Mandatory = $True, ValueFromPipeline = $false)]
        [string]
        [ValidateNotNullOrEmpty()]
        $text
    )

    $CurrentTime = Get-Date -UFormat '%H:%M:%S'   
     

    Switch ($category.ToUpper())
    {
        'INFO'
        {
            If ( $text )
            {
                $text = "$CurrentTime INFO   : $text" 
                Write-Host $text -ForegroundColor White
            }
            Else
            {
                Write-Host "Trace"
            }
        }

        'WARN'
        {
            $text = "$CurrentTime WARN   : $text"
            Write-Host $text -ForegroundColor Yellow
        }

        'ERR'
        {
            $text = "$CurrentTime ERROR  : $text"
            Write-Host $text -ForegroundColor Red
        }

        'TRACE'
        {
            Write-Verbose "$CurrentTime Trace  : $text"
        }
    }

}



#Check if a folder is empty
Function IsEmptyFolder
{
    param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $false)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_ })]
        [string]$FolderFullPath
    )

    $FolderItem = Get-Item $FolderFullPath
    $ChildItemCount = $FolderItem.GetFiles().Count

    return ($ChildItemCount -eq 0)
 }

#Get default VM path from Hyper-V host configuration
Function Get-VMDefaultPath
{
[CmdletBinding()]
Param(
)
    return (Get-VMHost).VirtualMachinePath
}

Function Get-VMDefaultVHDPath
{
[CmdletBinding()]
Param(
)
    return (Get-VMHost).VirtualHardDiskPath
}





#Get VHD(X) file partition style
function Get-VHDPartitionStyle 
{    
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [string]$Path 

    )           

    $VHDFile = Get-Item -Path $Path
    $CompressedFile = $VHDFile.Attributes -match "compressed"
    if ($CompressedFile) 
    {
        Write-ScriptMessage "Trace" "The OS template file $($VMOSDiskTemplate) is compressed, cannot be mounted to identify the partition style."
        $VHDDiskPartitionStyle = "UNKNOWN"
    }
    else 
    {
        Write-ScriptMessage "Trace" "Mount the file $($Path) to check partition style..."
        $VHDMountedDisk = Mount-DiskImage -ImagePath $Path -PassThru | Get-DiskImage | Get-Disk  -ErrorAction SilentlyContinue
        if ($VHDMountedDisk) 
        {
            $VHDDiskPartitionStyle = $VHDMountedDisk.PartitionStyle
            Write-ScriptMessage "Trace" "Partition style is $($VHDDiskPartitionStyle). Dismount the file $($Path)..."
            Dismount-DiskImage -ImagePath $Path
        }
        else 
        {
            Write-ScriptMessage "Trace" "Can't mount the file $($Path). Partition style is UNKNOWN."
            $VHDDiskPartitionStyle = "UNKNOWN"
        }
    }
    return $VHDDiskPartitionStyle
}



# Create new VMs
Function New-VirtualMachines
{
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True)]
    [Array]$VMConfiguration
)
    
    # check if the VM will be the virtual host (nested virtuallization)
    If($VMConfiguration.VM_TYPE -eq 0)
    {
        $VMasHost = $true       #VM is virtual host
        $VMParentPath = $VMConfiguration.VM_TYPE_HOST_PATH
    }
    Else 
    {
        $VMasHost = $False
        $VMParentPath = $VMConfiguration.VM_TYPE_VM_PATH
    }

    If (!(Test-Path -Path $VMParentPath)) 
    {
        Write-ScriptMessage "Trace" "$($VMParentPath) doesn't exist! Script exits, create it..."
        mkdir $VMParentPath -Force | Out-Null
    }

    $VMGen              = $VMConfiguration.VM_GENERATION
    $VMOSDiskTemplate   = $VMConfiguration.VM_OS_DISK_TEMPLATE
    If (!(Test-Path -Path $VMOSDiskTemplate -PathType Leaf)) 
    {
        Write-ScriptMessage "Err" "$($VMOSDiskTemplate) doesn't exist! Script exits."
        return -1
    }
    else 
    {
        $VMOSDiskPartitionStyle = Get-VHDPartitionStyle -Path $VMOSDiskTemplate
        if ((($VMOSDiskPartitionStyle -eq "GPT") -and ($VMGen -ne 2)) -or (($VMOSDiskPartitionStyle -eq "MBR") -and ($VMGen -ne 1)))
        {
            Write-ScriptMessage "Trace" "OS template partition is $($VMOSDiskPartitionStyle)."
            Write-ScriptMessage "Err" "Generation $($VMGen) virutal machine cannot use $($VMOSDiskPartitionStyle) partition."
            return -1
        }
        elseif ($VMOSDiskPartitionStyle -eq "UNKNOWN") 
        {
            Write-ScriptMessage "Warn" "Unknown partition sytle of virtual disk $($VMOSDiskTemplate)."
        }
    }

    $VMNamePrefix       = "$($VMConfiguration.VM_NAME_PREFIX)-"
    $VMProjectName      = $VMConfiguration.VM_PROJECT_NAME
    $VMProjectPath      = Join-Path $VMParentPath $VMProjectName
    $VMNumber           = $VMConfiguration.VM_NUMBER
    $VMHardware         = $VMConfiguration.VM_HARDWARE
    $VMPowerOn          = $VMConfiguration.VM_POWER_ON
    $VMNetwork          = $VMConfiguration.VM_NETWORK
    $VMSwitchName       = $VMNetwork.SWITCH
    $VMNICNumber        = $VMNetwork.ADAPTER_NUMBER

    $CPU                = $VMHardware.PROCESSOR_CORE
    $DataDiskNumber     = $VMHardware.DATA_DISK.NUMBER
    $DataDiskSize       = $VMHardware.DATA_DISK.SIZE / 1GB * 1GB
    $DataDiskType       = $VMHardware.DATA_DISK.TYPE    
    $DynamicMemory      = $VMHardware.MEMORY.DYNAMIC
    $MinimumMemory      = $VMHardware.MEMORY.MINIMUM / 1GB * 1GB
    $MaximumMemory      = $VMHardware.MEMORY.MAXIMUM / 1GB * 1GB
    $StartUpMemory      = $VMHardware.MEMORY.STARTUP / 1GB * 1GB
    $DVD_Drive          = $VMHardware.DVD_DRIVE
    $DVD_Image          = $VMHardware.DVD_IMAGE


    #check if swith exists. If not, create it as internal switch.
    Write-ScriptMessage "Trace" "Check virtual Switch: $($VMSwitchName)..."          
    $HostSwitch = Get-VMSwitch -Name $VMSwitchName -ErrorAction SilentlyContinue
    if (!$HostSwitch) 
    {
        Write-ScriptMessage "Warn" "The virtual Switch $($VMSwitchName) doesn't exist. `n Create it as internal switch..."
        #Create new swtich as internal type
        $HostSwitch = New-VMSwitch -Name $VMSwitchName -SwitchType Internal -ErrorAction SilentlyContinue
        if (!$HostSwitch) 
        {
            Write-ScriptMessage "Err" "$($Error[0]) - Cannot create internal switch! Script exists."
            return -1
        }  
        else 
        {
            Write-ScriptMessage "Trace" "$($VMSwitchName) was created successfully!"
        }
    }
    Write-ScriptMessage "Trace" "$VMSwitchName type is $($HostSwitch.SwitchType)."

    #Configure VM 
    If ($VMNumber -ge 100) 
    {
        $VMNumber = 99  #up to 99 VMs    
    }

    $numberCreated = 0
    For ($i=1; $i -le $VMNumber ; $i++)
    {
        $vmName = "$($VMNamePrefix)$("{0:D2}" -f $i)"
        $VMPath = Join-Path $VMProjectPath $vmName
        Write-ScriptMessage "Trace" "VM full path: $($VMPath)"

        Write-ScriptMessage "Trace" "Check if VM $($vmName) exists..."
        $VM = Get-VM -Name $vmName -ErrorAction SilentlyContinue
        If (!$VM) 
        {
            Write-ScriptMessage "Trace" "$($Error[0]) - VM $($vmName) doesn't exist, create it and attach to $($VMSwitchName)..."
            $VM = New-VM -Name $vmName -NoVHD -Path $VMProjectPath -Gen $VMGen -SwitchName $VMSwitchName -ErrorAction SilentlyContinue
            
            if (!$VM) {
                Write-ScriptMessage "Err" "$($Error[0]) - Failed to create VM!"
                return -1
            }  
            $numberCreated++              
        }
        else {
            Write-ScriptMessage "Trace" "$($vmName) exists. Continue to check other configurations..."

            #ignore the VM in running state. Otherwise, update the VM configuration based on input
            if ($VM.State -eq "Running") 
            {
                Write-ScriptMessage "Warn" "VM $($vmName) is running, ignore it."
                Continue
            }
        }

        Write-ScriptMessage "Trace" "Set CPU, memory to VM $($vmName)..."
        if ($DynamicMemory -eq 1) 
        {
            $vmCPU_Memory = @{
                        Name                = $vmName
                        ProcessorCount      = $CPU
                        MemoryStartupBytes  = $StartUpMemory
                        DynamicMemory       = $True
                        MemoryMinimumBytes  = $MinimumMemory
                        MemoryMaximumBytes  = $MaximumMemory
            }
           
            Write-ScriptMessage "Trace" "Dynamic memory is enabled. Set VM configuration."
            Set-VM @vmCPU_Memory    
        }
        else 
        {
            Set-VM -Name  $vmName -ProcessorCount $CPU  -MemoryStartupBytes $MaximumMemory -StaticMemory                
        }

        Write-ScriptMessage "Trace" "Set OS virtual disk..."
        #Get file extnesion based on template file, and generate the OS disk file name 
        $VMOSDiskName = "$($vmName)-OS$((Get-Item $VMOSDiskTemplate).Extension.ToUpper())"
        Write-ScriptMessage "Trace" "OS disk name: $($VMOSDiskName)"

        #check if the OS disk file already exists. 
        $DiskFiles = Get-ChildItem $VMProjectPath $VMOSDiskName -Recurse
        If ($DiskFiles.Count -ge 1)
        {
            #always attach the first disk file  
            $VMOSVHD = $DiskFiles[0].VersionInfo.FileName     
            Write-ScriptMessage "Trace" "OS VHD file $VMOSVHD exists."    
            
            #write file names to trace log
            If ($DiskFiles.Count -ge 2)
            {
                $fileNames = ""
                foreach ($filecount in 0..($DiskFiles.Count-1)) 
                {
                     $fileNames = "`t$($fileNames)File [$($filecount)]: $($DiskFiles[$filecount].VersionInfo.FileName)`n`t`t"
                }  
                Write-ScriptMessage "Warn" "Following $($DiskFiles.Count) OS files with the same name were found. The first one will be attached.`n$($fileNames)"
            }   
        }
        else 
        {
            $VMOSVHD = Join-Path $VMPath $VMOSDiskName
            Write-ScriptMessage "Trace" "Copying the OS disk file as $($VMOSVHD)..."
            Copy-Item $VMOSDiskTemplate -Destination $VMOSVHD

            Write-ScriptMessage "Trace" "Edit the disk and inject the computer name..."
            .\Deploy-VHD.ps1 -Edit -VHDPath $VMOSVHD -ComputerName $vmName -EnableAutoLogon
        }

        Write-ScriptMessage "Trace" "Checking the disk controller..."
        $ControllerType = "SCSI"
        if ($VMGen -eq 1) {

            #Gen 1 VM, IDE controller was already added.
            Write-ScriptMessage "Trace" "Generation 1 VM, IDE controller was already added."
            $ControllerType = "IDE"
            $VMDiskController = Get-VMIDEController -VMName $vmName -ControllerNumber 0
        }
        else 
        {
            #Gen 2 VM, need to check if SCSI controler was added or not. 
            $VMDiskController = Get-VMScsiController -VMName $vmName -ControllerNumber 0
            if (!$VMDiskController) 
            {
                Write-ScriptMessage "Trace" "Add first SCSI controller."
                $VMDiskController = Add-VMScsiController -VMName $vmName -Passthru
            }
        }
        
        # Attach OS disk and set it as boot device
        $ControllerNumber = $VMDiskController.ControllerNumber
        Write-ScriptMessage "Trace"  "Attaching the OS disk $($VMOSVHD)..."
        $VMHardDiskDrive = Get-VMHardDiskDrive -VMName $vmName -ControllerType $ControllerType -ControllerNumber $ControllerNumber -ControllerLocation 0
        if ($VMHardDiskDrive) 
        {
            Set-VMHardDiskDrive -VMName $vmName -Path $VMOSVHD -ControllerType $ControllerType -ControllerNumber $ControllerNumber -ControllerLocation 0            
        }
        else 
        {
            $VMHardDiskDrive = Add-VMHardDiskDrive -VMName $vmName -Path $VMOSVHD -ControllerType $ControllerType -ControllerNumber $ControllerNumber -ControllerLocation 0 -Passthru
        }

        #set the first boot device to OS disk
        Write-ScriptMessage "Trace"  "Set the first boot device to $($VMOSVHD)."
        Set-VMFirmware -VMName $vmName -FirstBootDevice $VMHardDiskDrive


        Write-ScriptMessage "Trace" "Checking $($DataDiskNumber) data disks and attach them ..."

        # Up to 63 data disks since Hyper-V SCSI controller supports to 64 disks.
        if ($DataDiskNumber -gt 63) 
        {
            $DataDiskNumber = 63
        }

        For ($j=1; $j -le $DataDiskNumber ; $j++)
        {
            $VMDataDiskName = "$($vmName)-Data$("{0:D2}" -f $j).VHDX"
            Write-ScriptMessage "Trace" "Data disk name: $($VMDataDiskName)"
            #check if the data disk file already exists. 
            #if multiple disk file with same name but different folder (sub folders), only the first one will be attached.
            $DiskFiles = Get-ChildItem $VMProjectPath $VMDataDiskName -Recurse
            If ($DiskFiles.Count -ge 1)
            {
                $VMDataVHD = $DiskFiles[0].VersionInfo.FileName     #always attach the first disk file  
                Write-ScriptMessage "Trace" "Data disk $($VMDataVHD) exists."    
                
                If ($DiskFiles.Count -ge 2)
                {
                    $fileNames = ""
                    foreach ($filecount in 0..($DiskFiles.Count-1)) 
                    {
                        $fileNames = "`t$($fileNames)File [$($filecount)]: $($DiskFiles[$filecount].VersionInfo.FileName)`n`t`t"
                    }  
                    Write-ScriptMessage "Warn" "Following $($DiskFiles.Count) data files with the same name (but in different folders) were found. The first one will be attached.`n$($fileNames)"
                }   
            }
            else 
            {
                $VMDataVHD = Join-Path $VMPath $VMDataDiskName
                Write-ScriptMessage "Trace" "Creating new data disk $($VMDataVHD)..."
                NEW-VHD -Dynamic $VMDataVHD -SizeBytes $DataDiskSize -InformationAction SilentlyContinue | Out-Null                
            }
            
            #Attach data disk to SCSI controller
            #For Gen 1 VM, SCSI controller was already added.
            #For Gen 2 VM, SCSI controller was added when adding OS disk.
            $VMHardDiskDrive = Get-VMHardDiskDrive -VMName $vmName -ControllerType SCSI -ControllerNumber $ControllerNumber -ControllerLocation $j
            if ($VMHardDiskDrive) 
            {
                Write-ScriptMessage "Trace" "Set current disk drive to disk $($VMDataVHD)."
                Set-VMHardDiskDrive -VMName $vmName -Path $VMDataVHD -ControllerType SCSI -ControllerNumber $ControllerNumber -ControllerLocation $j | Out-Null
            }
            else 
            {
                Write-ScriptMessage "Trace" "Add disk drive with virtual disk $($VMDataVHD)."
                Add-VMHardDiskDrive -VMName $vmName -Path $VMDataVHD -ControllerType SCSI -ControllerNumber $ControllerNumber -ControllerLocation $j | Out-Null            
            }
        }

        #add DVD drive for Gen 2 VM based on setting
        if (($VMGen -eq 2) -and ($DVD_Drive -eq 1)) 
        {
            $VMDVD_Drive = Get-VMDvdDrive -VMName $vmName
            If (!$VMDVD_Drive)
            {
                $VMDiskController = Get-VMScsiController -VMName $vmName -ControllerNumber 1

                if (!$VMDiskController) 
                {
                    #$VMDiskController = Add-VMScsiController -VMName $vmName -Passthru
                }
                
                $ControllerNumber = $VMDiskController.ControllerNumber

                #TODO... There is a bug in the Hyper-V module in Windows 10 about parameter "folderPath". 
                #Temporary disable DVD drive feature.
                #check at https://technet.microsoft.com/en-us/library/hh848576.aspx
                #$VMDVD_Drive = Add-VMDvdDrive -VMName $vmName -ControllerNumber $ControllerNumber  
                
                # insert the ISO file. FIle path is from Setting JSON file.
                if (($DVD_Image) -and ($DVD_Image.Length -lt 0))
                {
                    if (!(Test-Path $DVD_Image)) 
                    {
                        Write-ScriptMessage "Warn" "Cannot find the DVD image file $($DVD_Image)."
                    }
                    else 
                    {
                        Write-ScriptMessage "Trace" "Insert the image file $($VMDVD_Drive)."
                        #Set-VMDvdDrive -VMDvdDrive $VMDVD_Drive  -Path $DVD_Image
                    }
                }
            }
        }

        #Add additional network adapter if the VM is powered off.
        if ($VM.State -eq "Off") 
        {
            if ($VMNICNumber -ge 2)
            {
                #throttle to 8 NICs
                If ($VMNICNumber -gt 8)
                {
                    $VMNICNumber = 8
                }

                Write-ScriptMessage "Trace" "Need $($VMNICNumber) network adapters for virtual machine $($vmName)."
                $VMExistedNICNumber = (Get-VMNetworkAdapter -VMName $vmName).Count

                if (($VMExistedNICNumber) -and ($VMExistedNICNumber -ge $VMNICNumber)) 
                {
                    Write-ScriptMessage "Trace" "$($VMExistedNICNumber) network adapters alreay exist in $($vmName), skip it."
                }
                else {
                    $additionalNICNumber = $VMNICNumber - $VMExistedNICNumber
                    for ($j = 0; $j -lt $additionalNICNumber; $j++) 
                    {
                        Add-VMNetworkAdapter -VMName $vmName 
                    }
                }
            }
        }

        #enable nested hyper-v for VM as host
        If ($VMasHost) 
        {
            Write-ScriptMessage "Trace" "Enable Hyper-V on Hyper-V..."
            .\Enable-NestedVm.ps1 -vmName $vmName
        }

        #start VM if it is set to power on in settings file.
        if ($VMPowerOn -eq 1) {
            Start-VM -Name $vmName | Out-Null
        }
    }
    return $numberCreated    
}




# Remove VMs  
Function Remove-VirtualMachines
{

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False)]
    [Array]$VMConfiguration,   
    
    [Parameter(Mandatory=$False)]
    [switch]$Force
)
 if ($VMConfiguration)
 {   If($VMConfiguration.VM_TYPE -eq 0)
    {
        $VMasHost = $true
        $VMProjectPath = $VMConfiguration.VM_TYPE_HOST_PATH
    }
    Else 
    {
        $VMasHost = $False
        $VMProjectPath = $VMConfiguration.VM_TYPE_VM_PATH 
    }

    $VMProjectName      = $VMConfiguration.VM_PROJECT_NAME
    $VMProjectPath       = Join-Path $VMProjectPath $VMProjectName
    If (!(Test-Path -Path $VMProjectPath)) 
    {
        Write-ScriptMessage "Err" "$($VMProjectPath) doesn't exist! Script exits."
        return -1
    }

    $VMNamePrefix       = "$($VMConfiguration.VM_NAME_PREFIX)-*"
    $VMNumber           = $VMConfiguration.VM_NUMBER
}
else {      #if configuration file was not provided, means removing all VMs in the Hyper-V host.
    $VMNamePrefix       = "*"  #remove all VMs in the host.
}
    Write-ScriptMessage "Trace" "VM name prefix: $VMNamePrefix"
   
    $i = 0
    $sourceVMs = Get-VM -Name $VMNamePrefix -ErrorAction SilentlyContinue
    if($sourceVMs -eq $null)
    {
        Write-ScriptMessage "Trace" "No VM was found!" 
    }
    Else
    {
        Foreach($vm in $sourceVMs)
        {
            If($vm.State -eq "Running")
            {
                    Write-ScriptMessage "Trace" "VM is running. Shutding down the VM host $($vm.Name) ..."
                    Stop-VM -VM $vm -TurnOff
                    Start-Sleep -m 300  #wait for VM shuting down and then remove it.
            }
            Write-ScriptMessage "Trace" "Deleteing VM $($vm.Name) ..." 
            Remove-VM -VM $vm -Force

            If ($Force) 
            {
                Write-ScriptMessage "Trace" "Force removal, deleteing VM $($vm.Name) folder ..." 
                
                if ($VMConfiguration) {
                    $VMPath = Join-Path -Path $VMProjectPath -ChildPath $vm.Name                    
                }
                else {
                    $VMPath = $vm.Path
                }

                Remove-Item $VMPath -Recurse -Force -ErrorAction SilentlyContinue -WarningAction Continue 
            }
            
            #next
            $i++
        }

        #remove the project folder if all VM folders were removed when VM configuration file is provided.
        If (($Force) -and ($VMConfiguration)) 
        {
            Remove-Item $VMProjectPath -Recurse -Force -ErrorAction SilentlyContinue -WarningAction Continue
        }
    } 
    Write-ScriptMessage "Trace" "Removed $i VM(s)." 
    return $i
}



#Export VMs  
Function Export-VirtualMachines
{
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True)]
    [string]$NamePrefix,

    [Parameter(Mandatory=$False)]
    [string]$VMExportParentPath
    )

    #export all VMs if no prefix
    if (! $NamePrefix) 
    {
        $NamePrefix = '*'
    }
    Write-ScriptMessage "Trace" "Export Virtual Machine(s) with name prefix: $NamePrefix"

    #Use default VM folder in Hyper-V setting if no path
    if ($VMExportParentPath) 
    {
        $vmExportPath = $VMExportParentPath 
    }
    else 
    {
        $vmExportPath = Join-Path $(Get-VMDefaultPath) "Export"        
    }

    #Create the export path if not existing.
    If (!(Test-Path -Path $vmExportPath))
    {
        mkdir $vmExportPath -Force
    }
    Write-ScriptMessage "Trace" "Export folder: $vmExportPath"
    
    $i = 0
    $sourceVMs = Get-VM -Name $NamePrefix -ErrorAction SilentlyContinue
    if($sourceVMs -eq $null)
    {
        Write-ScriptMessage "Trace" "Warning: No VM was found!"
    }
    Else
    {
        Foreach($vm in $sourceVMs)
        {
            Write-ScriptMessage "Trace" "Exporting virtual machine $($vm.Name) ..."
            try {
                $exportedVM =  Export-VM -VM $vm -Path $vmExportPath -Passthru -ErrorAction Stop                
            }
            catch {
                Write-ScriptMessage "Warn" "$($Error[0])"
                $exportedVM = $null
            }
            if ($exportedVM) {
                $i++
                Write-ScriptMessage "Trace" "Exporte VM $($exportedVM.Name) successfully."    
            }
            
        }
    } 
    Write-ScriptMessage "Trace" "Exported $i VM(s)." 
    return $i    
}


Function Get-VMNameFromVMCXFile ($VMConfig) 
{
    $tempVM = (Compare-VM -Copy -Path $VMConfig -GenerateNewID).VM
    return $tempVM.VMName
}

# Import vm from source folder, settings from Settings.JSON file. 
Function Import-VirtualMachines
{

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True)]
    [string]$VMImportSourceParentPath,
    
    [Parameter(Mandatory=$False)]
    [string]$VMDestinationParentPath, 

    [Parameter(Mandatory=$False)]
    [switch]$VMPowerOn 
      
)
    
    #check if source path is valid.
    if (! (Test-Path $VMImportSourceParentPath)) 
    {
        Write-ScriptMessage "Err" "Can not find import source path: $VMImportSourceParentPath"
        return -1    
    }
   
   #if there is destination folder, then check if it exists, create it if not.
   if ($VMDestinationParentPath -and (!(Test-Path -Path $VMDestinationParentPath))) 
    {
        mkdir $VMDestinationParentPath -Force | Out-Null 
    }

    $i = 0

    $sourceVMs = Get-ChildItem $VMImportSourceParentPath -recurse -Filter *.VMCX
    if($sourceVMs -eq $null)
    {
        Write-ScriptMessage "Info" "Warning: No VM was found!" 
    }
    Else
    {
        Write-ScriptMessage "Trace" "Found $($sourceVMs.Count) VMCX file(s). Starting to import..."
        Foreach($sourceVMCX in $sourceVMs)
        {
            #Need to filter out the *.VMCX file under Snapshot folder
            if ($sourceVMCX.Directory.Name -like "Snapshots") 
            {
                Write-ScriptMessage "Trace" "$($sourceVMCX.VersionInfo.FileName) is snapshot file, ignore it."
                Continue
            }

            $sourceVMName = Get-VMNameFromVMCXFile($sourceVMCX.VersionInfo.FileName)
            $vm = Get-VM -Name $sourceVMName -ErrorAction SilentlyContinue
            if($vm -eq $null)
            {
                Write-ScriptMessage "Trace" "VM configuration file: $($sourceVMCX.VersionInfo.FileName)"

                if ($VMDestinationParentPath) 
                {
                    #import to destination folder
                    $destVMProjectPath = Join-Path -Path $VMDestinationParentPath -ChildPath $sourceVMName
                    Write-ScriptMessage "Info" "Copy mode, importing virtual machine $($sourceVMName) to $($destVMProjectPath)..."

                    $destVMVHDPath = Join-Path -Path $destVMProjectPath -ChildPath "Virtual Hard Disks"
                    $destVMVMProjectPath = Join-Path -Path $destVMProjectPath -ChildPath "Virtual Machines"
                    $destVMSnapshotPath = Join-Path -Path $destVMProjectPath -ChildPath "Snapshots"
                    Import-VM -Path $sourceVMCX.VersionInfo.FileName `
                              -VhdDestinationPath $destVMVHDPath `
                              -SnapshotFilePath $destVMSnapshotPath `
                              -VirtualMachinePath $destVMVMProjectPath `
                              -Copy | Out-Null
                }
                else 
                {
                    #import to source folder, just register it
                    Write-ScriptMessage "Info" "Register mode, importing Virtual Machine $($sourceVMName) ..."
                    Import-VM -Path $sourceVMCX.VersionInfo.FileName -Register | Out-Null
                }
                $i++
                if ($VMPowerOn) {
                    Start-VM -Name $sourceVMName | Out-Null
                }
            }
            Else
            {
                Write-ScriptMessage "Info" "VM $($sourceVMName) exists, skip the imorting."
            }
        }
    } 
    Write-ScriptMessage "Trace" "Imported $($i) VM(s)." 
    return $i
}

#Get windows installation is client of server.
Function Get-WindowsInstallationType()
{
    $regValue = Get-ItemProperty 'HKLM:\software\Microsoft\Windows NT\CurrentVersion' -Name "InstallationType"
    return $regValue.InstallationType
}

#chck if Hyper-v is installed.
Function IsHyperVInstalled()
{
    $osType = Get-WindowsInstallationType
    $hyperv = $False

    if ($osType -like "Client") 
    {
        $hyperVState = Get-WindowsOptionalFeature -online -FeatureName 'Microsoft-Hyper-V'
            $hyperv = ($hyperVState.State -eq "Enabled")
    }
    elseif ($osType -like "Server") 
    {
        $hyperVState = Get-WindowsFeature -Name 'Hyper-V'
        $hyperv = $hyperVState.Installed
    }
    return $hyperv
}


##########################################################################################
#endregion FUNCTIONS

##########################################################################################
# Main
##########################################################################################
# Banner text displayed during each run.
$banner = '='*80

$ScriptHeader    = @"
$banner
Lab VM Management.  Developed by Wei Luo.

THE SAMPLE SOURCE CODE IS PROVIDED "AS IS", WITH NO WARRANTIES.
Version $SCRIPT_VERSION
$banner

"@

Write-Host  $ScriptHeader

$StartTime= Get-Date -UFormat "%Y-%m-%d %H:%M:%S" #-Format yyyy-MM-dd/HH:MM:SS
Write-ScriptMessage "Info" "Script $SCRIPT_NAME starts at $StartTime."


##########################################################################################
#Check some prerequisites 


#Check if PowerShell is running in Elevated mode
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
If (!( $isAdmin )) {
	Write-ScriptMessage "Err" "Please run PowerShell in Elevated mode." 
	exit
}
Write-ScriptMessage "Trace" "PowerShell is running at elevated mode."

#Check if Hyper-V role is installed.
if (!(IsHyperVInstalled)) {
	Write-ScriptMessage "Err" "Please install Hyper-V role and run script again." 
	exit
}
Write-ScriptMessage "Trace" "Hyper-V was installed."


#Check if VM default folder exists or not.  
$VMDefaultPathInHost = Get-VMDefaultPath
if (! (Test-Path $VMDefaultPathInHost))
{
	Write-ScriptMessage "Err" "The default VM folder $($VMDefaultPathInHost) doesn't exist! please change it and run script again." 
	exit
}

#Check if VM default VHD folder exists or not.
$VMDefaultVHDPathInHost = Get-VMDefaultVHDPath
if (! (Test-Path $VMDefaultVHDPathInHost))
{
	Write-ScriptMessage "Err" "The default VHD folder $($VMDefaultVHDPathInHost) doesn't exist! please change it and run script again." 
	exit
}


##########################################################################################
#Prepare variables. 

#local host name
$LocalHostName = Get-LocalHostName
Write-ScriptMessage "Trace" "Local host name: $($LocalHostName)"

$VMConfigFilePath = Join-Path $PSScriptRoot $VMConfigurationFile 
$VMConfiguration = Get-Content $VMConfigFilePath | ConvertFrom-Json
$ret = 0

#process command set
Switch -Wildcard($PSCmdlet.ParameterSetName)
{
    "NEW"
    {
        Write-ScriptMessage "Info" "Start to create new virtual machine..."
        $ret = New-VirtualMachines -VMConfiguration $VMConfiguration
        Write-ScriptMessage "Info" "Create new VM status: $ret"
        break
    }
    
    "IMPORT"
    {
        $VMPowerOn = ($VMConfiguration.VM_POWER_ON -eq 1)
        if (! $ImportDestinationPath) 
        {   # register VMs
            Write-ScriptMessage "Info" "Start to import virtual machine in $($ImportSourcePath) ..."
            if ($VMPowerOn) 
            {
                #power on VM after importing
                $ret = Import-VirtualMachines -VMImportSourceParentPath $ImportSourcePath -VMPowerOn
            }
            else 
            {
                $ret = Import-VirtualMachines -VMImportSourceParentPath $ImportSourcePath 
            }
            Write-ScriptMessage "Info" "Imported $($ret) VM(s) from folder $($ImportSourcePath)."        
        }
        else 
        {   # Copy and import VMs
            $ImportDestinationPath  = Join-Path $ImportDestinationPath $VMConfiguration.VM_PROJECT_NAME
            Write-ScriptMessage "Info" "Start to import virtual machine from $($ImportSourcePath) to $($ImportDestinationPath)..."
            if ($VMPowerOn) 
            {
                #power on VM after importing
                $ret = Import-VirtualMachines -VMImportSourceParentPath $ImportSourcePath `
                                              -VMDestinationParentPath $ImportDestinationPath `
                                              -VMPowerOn                
            }
            else 
            {
                $ret = Import-VirtualMachines -VMImportSourceParentPath $ImportSourcePath `
                                              -VMDestinationParentPath $ImportDestinationPath `
            }

            Write-ScriptMessage "Info" "Imported $($ret) VM(s) to folder $($ImportDestinationPath)."        
        }
        
        break
    }
    
    "EXPORT"
    {
        $ExportDestinationPath  = Join-Path $ExportDestinationPath $VMConfiguration.VM_PROJECT_NAME
        $VMNamePrefix           = "$($VMConfiguration.VM_NAME_PREFIX)*"
        Write-ScriptMessage "Info" "Start to export virtual machine $($VMNamePrefix) to $($ExportDestinationPath)..."
        $ret = Export-VirtualMachines -NamePrefix $VMNamePrefix -VMExportParentPath $ExportDestinationPath
        Write-ScriptMessage "Info" "Exported $($ret) VM(s) to folder $($ExportDestinationPath)."

        break
    }

    "REMOVE"
    {
        $ret = 0
        Write-ScriptMessage "Info" "Start to remove virtual machine..."

        if ($ForceRemoval) {
            Write-ScriptMessage "Warn" "ForceRemoval will remove all related VMs and folders/files."
            $UserInput = Read-Host -Prompt "Please confirm to proceed force the removal. Y/N"
            if ($UserInput.ToUpper() -eq 'Y') 
            {
                $ret = Remove-VirtualMachines -VMConfiguration $VMConfiguration -Force            
            }
            else {
                Write-ScriptMessage "Info" "Not confirmed. Skip the removal."
            }
        }
        else {
            $ret = Remove-VirtualMachines -VMConfiguration $VMConfiguration            
        }
        
        $returnMessage = "$($ret) VMs were removed."
        if ($ret -le 1) {
            $returnMessage = "$($ret) VM was removed."
        }

        Write-ScriptMessage "Info" $returnMessage

        break
    }    
    
    "REMOVEALL"    
    {
        $ret = 0
        Write-ScriptMessage "Info" "Start to remove all virtual machine(s) in the host..."

        if ($ForceRemoval) 
        {
            Write-ScriptMessage "Warn" "ForceRemoval will remove all related VMs and folders/files."
            $UserInput = Read-Host -Prompt "Please confirm to proceed the force removal. Y/N"
            if ($UserInput.ToUpper() -eq 'Y') 
            {
                $ret = Remove-VirtualMachines -Force
            }
            else 
            {
	            Write-ScriptMessage "Info" "Not confirmed. Skip the removal."
            }
        }
        else {
            $ret = Remove-VirtualMachines             
        }
        
        $returnMessage = "$($ret) VMs were removed."
        if ($ret -le 1) {
            $returnMessage = "$($ret) VM was removed."
        }

        Write-ScriptMessage "Info" $returnMessage

        break
    }

    "DEFAULT"
    {
        #TODO: ADD PROCESS

        break
    }
}

#complete script, display the time when completing. 
$EndTime= Get-Date -UFormat "%Y-%m-%d %H:%M:%S" #-Format yyyy-MM-dd/HH:MM:SS
Write-ScriptMessage "Info" "Script $SCRIPT_NAME completed at $EndTime. Started at $StartTime."

#endregion CODE
