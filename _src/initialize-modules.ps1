$Debug = $True


Start-Transcript -path C:\bb\setup_transcript.txt -IncludeInvocationHeader -Append



#region Basic system tasks

    function Set-KeyboardLayout {
        $currentL = (Get-WinUserLanguageList)
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
        New-Item -path $profile -itemType File -force
    }

#endregion Basic system tasks




#region Modules installation

    function Initialize-Modules {

        Install-PackageProvider -name NuGet -minimumVersion 2.8.5.208 -force -verbose
        Set-PSRepository -name 'psGallery' -installationPolicy Trusted

        Install-Module PowershellGet, SecurityFever -force
        Import-Module PowershellGet, SecurityFever -force

    }


    function Install-Chocolatey {
        Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1') -verbose
     
	    Install-PackageProvider ChocolateyGet -force -verbose
        Import-PackageProvider ChocolateyGet -force
    }





    "initialize-modules.ps1: Initialize modules Start"
    Initialize-Modules
    $packages = Import-PowerShellDataFile "$psScriptRoot\packages.psd1"
    "initialize-modules.ps1: Initialize modules Finish"

    #region install Chocolatey & basic packages
        "initialize-modules.ps1: install Chocolatey & basic packages Start"
        Install-Chocolatey
        c:\bb\Install-ChocolateyPackages.ps1 -package $packages.Chocolatey.Bootstrap
        "initialize-modules.ps1: install Chocolatey & basic packages Finish"
    #endregion install Chocolatey & basic packages
     

    #region install Scoop
        "initialize-modules.ps1: install scoop Start"

        $InstallScoop = {

            function Install-ScoopPackages {
	            PARAM(
		            [Parameter( Mandatory )]
		            [Object[]] $package
	            )

                $allOptions = , 'global'
	
	            $package | ForEach-Object { 
                    $command = "scoop install" 
                    if ($_.options) 
                    {
                        if ($_.name) {
                            $command += ' ' + $_.name.Trim()
                        } else {
                            $dump = ($_ | Format-List | Out-String).Trim()
                            throw "Package name is missing in Install-ScoopPackages():`n$dump"
                        }

                        foreach ($option in $_.options) 
                        {
                            $normOption = $option.Trim().ToLower()
                            if ( $normOption -in $allOptions ) {
                                $command += " --$normOption "
                            } else {
                                throw "Unknown option '$normOption' for Install-ScoopPackages()"
                            }
                        }
                    } else {
                        $command += ' ' + $_.Trim()
                    }
                    Invoke-Expression -command $command
                }
            }

            Start-Transcript -path C:\bb\setup_transcript_scoop.txt -IncludeInvocationHeader -Append

		    $params = @{
		        path = 		    'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
		        name = 		    'SCOOP_GLOBAL' 
		        propertyType = 	'ExpandString' 
		        value = 	    "${ENV:PROGRAMDATA}\scoop"
		    }
		    New-ItemProperty @params -force

	        Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh') -verbose

            scoop bucket add Extras
            scoop bucket add Nirsoft

            $packages = Import-PowerShellDataFile "c:\bb\packages.psd1"
            Install-ScoopPackages $packages.Scoop

            Stop-Transcript
        }

        Start-Job -name installScoop -scriptBlock $installScoop

        "initialize-modules.ps1: install scoop Finish"
    #endregion install Scoop


    #region install other packages
        "initialize-modules.ps1: install other packages Start"

        $installGit = {
            Start-Transcript -path C:\bb\setup_transcript_git.txt -IncludeInvocationHeader -Append

            $packages = Import-PowerShellDataFile "c:\bb\packages.psd1"
            c:\bb\Install-ChocolateyPackages.ps1 -package $packages.chocolatey.Git

            Stop-Transcript
        }
        Start-Job -name installGit -scriptBlock $installGit

        $installLight = {
            $packages = Import-PowerShellDataFile "c:\bb\packages.psd1"
            c:\bb\Install-ChocolateyPackages.ps1 -package $packages.chocolatey.Light
        }
        #Start-Job -name installLight -scriptBlock $installLight

        $installExtra = {
            $packages = Import-PowerShellDataFile "c:\bb\packages.psd1"
            c:\bb\Install-ChocolateyPackages.ps1 -package $packages.chocolatey.Extra
        }
        #Start-Job -name installExtra -scriptBlock $installExtra

        "initialize-modules.ps1: install other packages Finish"
    #endregion install other packages

#endregion Modules installation



Stop-Transcript