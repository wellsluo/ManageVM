# ManageVM
README: [English](https://github.com/wellsluo/ManageVM/blob/master/README.md) | [中文](https://github.com/wellsluo/ManageVM/blob/master/README-CN.md)

用以管理基于JSON配置文件的多个虚拟机的自动化PowerShell脚本。 

<!-- TOC -->

- [ManageVM](#managevm)
    - [缘起](#缘起)
    - [目标](#目标)
    - [授权](#授权)
    - [特性](#特性)
    - [可支持性](#可支持性)
        - [系统运行需求](#系统运行需求)
    - [使用方式](#使用方式)
        - [示例1](#示例1)
        - [示例2](#示例2)
        - [示例3](#示例3)
        - [示例4](#示例4)
        - [示例5](#示例5)
        - [示例6](#示例6)
    - [帮助](#帮助)
    - [依赖性](#依赖性)
        - [Deploy-VHD.ps1](#deploy-vhdps1)
        - [Enable Nested VM](#enable-nested-vm)

<!-- /TOC -->


## 缘起

当我在准备一个演示环境的时候，我需要在20多台Hyper-V物理计算机上，每台添加10台配置类似的虚机。即便是在一台物理机上建立好虚拟机作为模板，导出、然后在导入到其他物理机上，这也是一件极其枯燥的事儿。我相信没有几个人有耐心在 Hyper-V 控制台上干这件事情。因此，自动化脚本一定是管理大规模虚拟机的最佳方式。  


## 目标

使用PowerShell脚本来建立、导出、导入或者删除具有同样配置的虚拟机，管理员只需设置JSON配置文件，然后运行此脚本即可。当然，编辑已经存在的虚拟机，以使它的配置符合需求也是必需的任务。


## 授权

此项目采用 MIT 授权协议。详细内容，请参考 [LICENSE](https://github.com/wellsluo/ManageVM/blob/master/LICENSE) 文件。

## 特性

本脚本使用"Project" 的术语来作为所有虚拟机存放文件和配置的入口文件夹。每一台虚拟机将根据配置文件中的设置使用相同的名称前缀，存放文件夹的名称和虚拟机名称一致。 这些设置都包含在采用JSON格式的配置文件中，涵盖以下可用设置：

- Project 名称
- 虚拟机的类型（虚拟机是否作为嵌套虚拟化的主机来使用）
- 指定操作系统磁盘模板
- 虚拟机数量
- 虚拟机命名前缀
- 1代或者2代虚拟机
- 建立虚拟机之后立即启动
- 网络适配器设置
- 硬件设置（处理器、内存和数据磁盘）


管理虚拟机的任务： 
- 建立新的虚拟机 
	- 第1代或者第2代。
	- 检查操作系统磁盘分区的类型（GUID 还是 MBR）。
	- 建立 "Internal" 类型的虚拟交换机。
	- 使用配置文件中的设置，更新已经存在的虚拟机。
	- 根据 VHD(X) 模板文件建立操作系统盘。
	- 添加 SCSCI 控制器上的数据磁盘（最多 63 块磁盘）。
	- 添加虚拟网络适配器，并连接到指定的虚拟交换机。
	- 如果需要，启用嵌套虚拟化功能。 
- 导出已经存在的虚拟机
	- 根据 JSON 配置文件导出虚拟机
- 导入虚拟机
	- 如果提供了目标文件夹路径，将所有虚拟机导入到同一个 Project 文件夹。
	- 如果未提供目标文件夹路径，将直接使用虚拟机当前文件夹，然后在 Hyper-V 中注册虚拟机。 
	- 忽略在 Snapshot 目录下的虚拟机配置文件（VMCX）。
- 移除虚拟机（可强制移除文件夹）
	- 根据 JSON 配置文件移除相应虚拟机。
	- 移除所有虚拟机。
	- 还在运行的虚拟机将直接关机并移除。
- 使用 "-ForceFully" 开关时，将强制移除所有文件和文件夹。

Hyper-V 角色在计算机上的安装状态会被检查。

PowerShell 控制台需要运行在管理员模式。
 
## 可支持性
 
### 系统运行需求
要运行脚本，您需要以下操作系统版本和 PowerShell 版本：
- Windows Server 2016
- Windows 10
- PowerShell 4 或以上版本，运行在管理员模式

## 使用方式
将所有文件复制到同一个文件夹，然后以管理员方式启动 PowerShell 控制台窗口，转到脚本的目录下，运行即可。

文件说明参考下表：

文件名称 | 描述 | 备注
------------ | ------------- | ------------
Manage-VM.ps1 | 主要脚本 | 
DeployVHD.ps1 | 基础脚本  | 设置操作系统盘的无人值守选项
Example.Manage-VM.ps1 | 示例脚本  | 使用Manage-VM.ps1脚本建立多台不同类型虚拟机
Example.Manage-VM.Settings.Client.JSON | 示例配置文件  | 客户端虚拟机配置
Example.Manage-VM.Settings.DomainController.JSON | 示例配置文件  | 域控制器虚拟机配置
Example.Manage-VM.Settings.S2D.JSON | 示例配置文件  | 存储虚拟机配置
Example.Manage-VM.Settings.SDN.JSON | 示例配置文件  |网络虚拟机配置
unattend_amd64_Client.xml | 无人值守文件 | 桌面端版本
unattend_amd64_Server.xml | 无人值守文件 | 服务器端版本



### 示例1

```PowerShell
    .\Manage-VM.PS1 
```

使用默认配置文件 Manage-VM.Setting.JSON 建立新的虚拟机。

### 示例2

```PowerShell
    .\Manage-VM.PS1 -VMCF .\Manage-VM.Settings.ProjectAlpha.JSON 
```

使用 Manage-VM.Settings.ProjectAlpha.JSON 配置文件来建立新的虚拟机。

### 示例3

```PowerShell
    .\Manage-VM.PS1 -Export -ExportDestinationPath V:\VM\Exported 
```

导出虚拟机到文件夹 V:\VM\Exported，需要导出的虚拟机名称在 Manage-VM.Setting.JSON 配置文件中提供。Project 名称将作为入口文件夹名称。

### 示例4

```PowerShell
    .\Manage-VM.PS1 -ForceRemoval -VMCF .\Manage-VM.Settings.ProjectAlpha.JSON  
```

 使用配置文件 Manage-VM.Settings.ProjectAlpha.JSON 中的信息删除相应虚拟机。


### 示例5

```PowerShell
    .\Manage-VM.PS1 -Import -ImportSourcePath V:\VM\Exported\ProjectAlpha -ImportDestinationPath V:\VM
```

复制虚拟机到目标文件夹并导入虚拟机。


### 示例6

```PowerShell
    .\Manage-VM.PS1 -Import -ImportSourcePath V:\VM\ProjectAlpha
```
直接使用原始文件夹来注册虚拟机以完成导入任务。

## 帮助
本脚本遵循 PowerShell 标准的帮助方式。可运行以下命令来获取帮助：  

```PowerShell

Help .\Manage-VM.PS1 -Detailed
 
```

## 依赖性

### Deploy-VHD.ps1
本脚本使用 'Deploy-VHD.ps1' 来配置操作系统盘的无人值守选项。

'Deploy-VHD.ps1' 版本 2.0.100.Main.20170218.1015.0.Release 包含在文件列表中。 

有关脚本 'Deploy-VHD.ps1' 的具体信息，请参考我的另一个项目：
https://github.com/wellsluo/DeployVHD


### Enable Nested VM
脚本 'Enable-NestedVm.ps1" 用来启用Hyper-V的嵌套虚拟化功能。

请参考如下Blog:
[Windows Insider Preview: Nested Virtualization](https://blogs.technet.microsoft.com/virtualization/2015/10/13/windows-insider-preview-nested-virtualization/)
