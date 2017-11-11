$paramsUnattended = @{
    path = "$PSscriptRoot\_src\Unattend.xml"
    logonCount = 100
    computerName = 'devBox'
    registeredOrganization = 'ƋБ'
    registeredOwner = 'mao 毛'
    firstBootExecuteCommand = @(
        @{
            Description = 'Enable script execution'
            Order = 1
            Path = '%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -noProfile -command "Set-ExecutionPolicy -executionPolicy RemoteSigned -scope LocalMachine -force" '
        },
        @{
            Description = 'Move swap file'
            Order = 2
            Path = "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -noProfile -command 'Set-ItemProperty -path `"HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management`" -name `"PagingFiles`" -value `"d:\pagefile.sys 0 0`" ' "
        },
        @{
            Description = 'Other PC initialization tasks'
            Order = 3
            Path = '%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -noProfile -file "c:\bb\Invoke-1stBoot.ps1" '
        }
    )
    firstLogonExecuteCommand = @(
        @{
            Description = 'Initialize PackageManagement and module providers'
            Order = 1
            CommandLine = '%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -noProfile -file "c:\bb\initialize-modules.ps1" '
        }
    )
    enableAdministrator = $True
    userAccount         = "Tester"
    timeZone            = 'FLE Standard Time'
    inputLocale         = 'en-US;uk-UA'
    systemLocale        = 'uk-UA'
    UILanguage          = 'en-US'
    architecture        = 'amd64'
}

New-UnattendXml @paramsUnattended

$paramsVHD = @{
    path =          'S:\VMs\devBase\test.vhdx'
    size =          25GB
    dynamic =       $True 
    diskLayout =    'UEFI' 
    recoveryTools = $False 
    recoveryImage = $False 
    nativeBoot =    $False 
    unattend =      "$PSscriptRoot\_src\Unattend.xml" 
    sourcePath =    'b:\ISOs\Windows 10\1709\rs3\install.wim'
    filesToInject = "$PSscriptRoot\_dist\bb"
    force =         $True
    verbose =       $True
}

Convert-Wim2VHD @paramsVHD
