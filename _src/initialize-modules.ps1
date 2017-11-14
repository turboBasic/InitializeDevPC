$Debug = $True
$VerbosePreference = 'Continue'

. c:\bb\lib\install-packages.ps1
$Packages = Import-PowerShellDataFile c:\bb\packages.psd1

Start-Transcript -path C:\bb\setup_transcript.txt -IncludeInvocationHeader -Append


#region Basic system tasks
    "initialize-modules.ps1: Basic system tasks Start" | Write-Verbose

    function Set-KeyboardLayout {
        $currentL = Get-WinUserLanguageList
        $currentL[0].InputMethodTips.Clear()
        $currentL[0].InputMethodTips.Add('0409:00020409')
        $currentL += New-WinUserLanguageList uk-UA
        Set-WinUserLanguageList $currentL -force

        $RegKey = 'HKCU:\Keyboard Layout\Toggle'
        Set-ItemProperty -path $RegKey -name 'HotKey' -value '2'
        Set-ItemProperty -path $RegKey -name 'Language HotKey' -value '2'
        Set-ItemProperty -path $RegKey -name 'Layout HotKey' -value '1'
    }

    Set-KeyboardLayout

    if (-not( Test-Path $profile)) {
        New-Item -path (Split-Path -parent $profile) -itemType Directory -errorAction SilentlyContinue
        New-Item -path $profile -itemType File
        $dummyString = "`n# Dummy content to satisfy Chocolatey Tab completion installer"
        Add-Content -path $profile -value $dummyString
        $ISEprofile = (Split-Path -leaf $profile) -replace 'PowerShell_profile.ps1', 'PowerShellISE_profile.ps1'
        $ISEprofile = Join-Path (Split-Path -parent $profile) $ISEprofile
        Add-Content -path $ISEprofile -value $dummyString
    }

    "initialize-modules.ps1: Basic system tasks Finish" | Write-Verbose
#endregion Basic system tasks



#region initialize modules
"initialize-modules.ps1: Initialize modules Start" | Write-Verbose

    function Initialize-Modules {

        $Nuget = Get-PackageProvider -listAvailable | Where-Object Name -eq 'NuGet' | Sort-Object -descending Version
        if (-not $Nuget -or $Nuget[0].Version -lt [System.Version]'2.8.5.210') {
            Install-PackageProvider -name NuGet -minimumVersion 2.8.5.208 -force -verbose
        }    
        Set-PSRepository -name 'psGallery' -installationPolicy Trusted

        if ((Get-Module PowershellGet -listAvailable | Sort -descending Version)[0].Version -lt [System.Version]'1.5.0.0') {
            Install-Module PowershellGet -force
        }
        Install-Module SecurityFever
        Import-Module PowershellGet, SecurityFever

    }

    Initialize-Modules

"initialize-modules.ps1: Initialize modules Finish" | Write-Verbose
#endregion initialize modules


#region install Chocolatey & basic packages
"initialize-modules.ps1: install Chocolatey & basic packages Start" | Write-Verbose

    function Install-Chocolatey {
        Invoke-WebRequest -useBasicParsing https://chocolatey.org/install.ps1 | Invoke-Expression -verbose
     
	    Install-PackageProvider ChocolateyGet -verbose
        Import-PackageProvider ChocolateyGet
    }

    Install-Chocolatey
    Install-ChocolateyPackage -package $Packages.Chocolatey.Bootstrap
    . $profile
    RefreshEnv

"initialize-modules.ps1: install Chocolatey & basic packages Finish" | Write-Verbose
#endregion install Chocolatey & basic packages
     


#region install Git
"initialize-modules.ps1: install Git Start"  | Write-Verbose

    Install-ChocolateyPackage -package $Packages.chocolatey.Git

    RefreshEnv

"initialize-modules.ps1: install Git Finish" | Write-Verbose
#endregion install Git



#region install Scoop
"initialize-modules.ps1: install scoop Start" | Write-Verbose
    
    if (-not (Test-Path Env:Scoop_Global)) {
	    New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -name scoop_GLOBAL -propertyType ExpandString -value '%ProgramData%\scoop'  
    }

    try {
        if (Test-Path (scoop which scoop)) {
            'Scoop is already installed' | Write-Verbose
        }
    } catch {
        Invoke-WebRequest -useBasicParsing https://get.scoop.sh | Invoke-Expression -verbose
        RefreshEnv
    }

    scoop bucket add Extras
    scoop bucket add Nirsoft

    Install-ScoopPackage -package $Packages.Scoop.Basic

"initialize-modules.ps1: install scoop Finish" | Write-Verbose
#endregion install Scoop



#region install other packages
"initialize-modules.ps1: install other packages Start"  | Write-Verbose

    $installLight = {
        Start-Transcript -path C:\bb\setup_transcript_light.txt -IncludeInvocationHeader -Append

        $Packages = Import-PowerShellDataFile c:\bb\packages.psd1
        . c:\bb\lib\install-packages.ps1

        Install-ChocolateyPackage -package $packages.chocolatey.Light

        Stop-Transcript
    }

    if (Test-path c:\bb\.install-light) {
        Start-Job -name installLight -scriptBlock $installLight
    } else {
        "Packages.Chocolatey.Light are skipped due to absense of .install-light marker file" | Write-Verbose
    }



    $installExtra = {
        Start-Transcript -path C:\bb\setup_transcript_extra.txt -IncludeInvocationHeader -Append

        $Packages = Import-PowerShellDataFile c:\bb\packages.psd1
        . c:\bb\lib\install-packages.ps1

        Install-ChocolateyPackage -package $Packages.chocolatey.Extra

        Stop-Transcript
    }

    if (Test-path c:\bb\.install-extra) {
        Start-Job -name installExtra -scriptBlock $installExtra
    } else {
        "Packages.Chocolatey.Extra are skipped due to absense of .install-extra marker file" | Write-Verbose
    }


"initialize-modules.ps1: install other packages Finish" | Write-Verbose
#endregion install other packages


Stop-Transcript