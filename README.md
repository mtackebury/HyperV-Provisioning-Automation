Hyper-V VM Provisioning Script (PowerShell)
Overview

This PowerShell script automates the creation and updating of Hyper-V virtual machines.

It supports:

Creating new Generation 2 VMs
Attaching existing VHDX files
Creating new VHDX files automatically
Updating CPU and memory on existing VMs
Reconnecting network adapters to a specified vSwitch
Safe execution using -WhatIf and -Confirm
The script is designed to be idempotent-aware and safe for repeated execution.

Features
Uses the Hyper-V host’s default VirtualHardDiskPath if no VHD folder is specified
Automatically creates the VHD folder if it does not exist
Gracefully stops and restarts a VM during updates if required
Validates that the specified virtual switch exists
Supports -WhatIf and -Confirm via SupportsShouldProcess

Requirements
Windows Server or Windows 10/11 with Hyper-V enabled
Hyper-V PowerShell module
Administrative privileges
PowerShell 5.1 or later

Parameters
| Parameter   | Type   | Required | Default      | Description                                     |
| ----------- | ------ | -------- | ------------ | ----------------------------------------------- |
| `VMName`    | String | Yes      | —            | Name of the virtual machine                     |
| `VMSwitch`  | String | Yes      | —            | Name of the Hyper-V virtual switch              |
| `MemoryMB`  | Int    | No       | 2048         | Startup memory in MB                            |
| `CPU`       | Int    | No       | 2            | Number of virtual processors                    |
| `VHDSizeGB` | Int    | No       | 64           | Size of the VHD in GB                           |
| `VHDFolder` | String | No       | Host default | Folder to store the VHDX file                   |
| `Update`    | Switch | No       | —            | Modify existing VM instead of throwing an error |


Usage Examples:
Create a New VM
.\New-HyperVVM.ps1 `
    -VMName "Lab-01" `
    -VMSwitch "Internal" `
    -MemoryMB 4096 `
    -CPU 4 `
    -VHDSizeGB 80

Create a VM Using Default Host VHD Location:
.\New-HyperVVM.ps1 `
    -VMName "Dev-VM" `
    -VMSwitch "LAN"


If -VHDFolder is not specified, the script uses:
(Get-VMHost).VirtualHardDiskPath

Update an Existing VM:
.\New-HyperVVM.ps1 `
    -VMName "Lab-01" `
    -VMSwitch "Internal" `
    -CPU 8 `
    -MemoryMB 8192 `
    -Update

If the VM is running, it will:
Stop the VM
Apply changes
Restart the VM

Preview Changes (Safe Mode):
.\New-HyperVVM.ps1 `
    -VMName "TestVM" `
    -VMSwitch "LAN" `
    -WhatIf
Displays what actions would occur without modifying the system.

Error Handling

The script will:
Throw an error if the specified virtual switch does not exist
Throw an error if the VM already exists and -Update is not specified
Stop execution if the VHD folder cannot be determined
Catch and report failures during VM shutdown or startup
