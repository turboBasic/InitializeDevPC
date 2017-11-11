$vmName =      'test'
$vhdBasePath = 'S:\VMs\devBase'

$vhd =         'test-02.vhdx'
$vhdFullPath = (Join-Path $vhdBasePath $vhd)

$vhdParent =   'test.vhdx'
$vhdParentFullPath = (Join-Path $vhdBasePath $vhdParent)


Remove-VMHardDiskDrive -vmName $vmName -controllerType SCSI -controllerNumber 0 -controllerLocation 0
Rename-Item $vhdFullPath -newName ( $vhd -replace '\.vhdx$', "-$(Get-Date -UFormat %Y%m%d-%H%M%S).vhdx" )
New-VHD -path $vhdFullPath -parentPath $vhdParentFullPath -differencing
Add-VMHardDiskDrive -vmName $vmName -path $vhdFullPath


$bootOrder=(Get-VMFirmware -vmName $vmName).BootOrder
$1stBootDeviceId = ( $bootOrder | 
                        ForEach-Object Device | 
                        Where-Object {
                            $_.ControllerLocation -eq 0 -and 
                            $_.ControllerNumber -eq 0 -and 
                            $_.ControllerType -eq 'SCSI'
                        }
).Id
$1stBootDevice = $bootOrder | Where-Object { $_.Device.Id -eq $1stBootDeviceId }
$otherDevices =  $bootOrder | Where-Object { $_.Device.Id -ne $1stBootDeviceId }
Set-VMFirmware -vmName $vmName -bootOrder ( ,$1stBootDevice + $otherDevices )