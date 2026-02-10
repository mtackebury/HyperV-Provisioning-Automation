[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$VMName,
    [Parameter(Mandatory)]
    [string]$VMSwitch,
    [ValidateRange(512, 262144)]
    [int]$MemoryMB=2048,
    [ValidateRange(1, 64)]
    [int]$CPU=2,
    [ValidateRange(1, 2048)]
    [int]$VHDSizeGB=64,
    [string]$VHDFolder,
    [switch]$Update
)

# Check if switch exist
if (-not (Get-VMSwitch -Name $VMSwitch -ErrorAction SilentlyContinue)) {
    $available = (Get-VMSwitch).Name -join ", "
    throw "Error: $($VMSwitch) does not exist. Available VMSwitches: $($available)"
}

# Used as default VHD path is none is supplied
if (-not $VHDFolder) {
    $VHDFolder = (Get-VMHost).VirtualHardDiskPath
}

# Check if VHD default path exist
if (-not $VHDFolder) { 
    throw "No VHDFolder provided and Hyper-V host default VirtualHardDiskPath is not set." 
 }

$vm = Get-VM -Name $VMName -ErrorAction SilentlyContinue
$null = New-Item -ItemType Directory -Force -Path $VHDFolder
$VHDPath = Join-Path $VHDFolder "$VMName.vhdx"


# Update existing and if -Update switch is used
if ($vm -and $Update){
    $wasRunning = $false
    # Stop VM if running
    if ($PSCmdlet.ShouldProcess($VMName, "VM $VMName exist, server will be updated")) {
        if ($vm.State -eq "Running"){
            try{
                Stop-VM -Name $VMName -TurnOff:$false -Force -ErrorAction Stop
                $wasRunning = $true
            }catch{
                Write-Error "Unable to Shutdown $VMName VM."
                return
            }
        }

        Set-VM `
            -Name $VMName `
            -ProcessorCount $CPU `
            -MemoryStartupBytes ($MemoryMB * 1MB)

        Get-VMNetworkAdapter -VMName $VMName | Connect-VMNetworkAdapter -SwitchName $VMSwitch

        #Start VM if was stopped
        if ($wasRunning){
            try{
                Start-VM -Name $VMName -ErrorAction Stop
            }catch{
                Write-Error "Unable to start $VMName VM."
                return
            }
        }
        return Write-Output "Found VM with same name. Resources updated"
    }
}elseif ($vm -and (-not $Update)) {
    throw "Error: VMName already exist. Use -Update to modify existing Virtual Machines"
}

# Create VM if it doesn't exist
if (-not $vm) {
    if ($PSCmdlet.ShouldProcess($VMName, "Create New VM")) {

        if (-not (Test-Path $VHDPath)) {
            New-VM `
                -Name $VMName `
                -MemoryStartupBytes ($MemoryMB * 1MB) `
                -SwitchName $VMSwitch `
                -NewVHDPath $VHDPath `
                -NewVHDSizeBytes ($VHDSizeGB * 1GB) `
                -Generation 2 | Out-Null
        }else {
            New-VM `
                -Name $VMName `
                -MemoryStartupBytes ($MemoryMB * 1MB) `
                -SwitchName $VMSwitch `
                -VHDPath $VHDPath `
                -Generation 2 | Out-Null
        }

        Set-VM -Name $VMName -ProcessorCount $CPU
        Write-Output "Created VM '$VMName' with VHD '$VHDPath'."
    }
}