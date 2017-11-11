$Debug = $True
$VerbosePreference = 'Continue'

. c:\bb\install-chocolateyPackages.ps1
$Packages = Import-PowerShellDataFile c:\bb\packages.psd1

Start-Transcript -path C:\bb\setup_transcript.txt -IncludeInvocationHeader -Append


#region Basic system tasks
    "initialize-modules.ps1: Basic system tasks Start" | Write-Verbose

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

        Install-PackageProvider -name NuGet -minimumVersion 2.8.5.208 -force -verbose
        Set-PSRepository -name 'psGallery' -installationPolicy Trusted

        Install-Module PowershellGet, SecurityFever -force
        Import-Module PowershellGet, SecurityFever -force

    }

    Initialize-Modules

"initialize-modules.ps1: Initialize modules Finish" | Write-Verbose
#endregion initialize modules


#region install Chocolatey & basic packages
"initialize-modules.ps1: install Chocolatey & basic packages Start" | Write-Verbose

    function Install-Chocolatey {
        Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1') -verbose
     
	    Install-PackageProvider ChocolateyGet -force -verbose
        Import-PackageProvider ChocolateyGet -force
    }

    Install-Chocolatey
    Install-ChocolateyPackage -package $Packages.Chocolatey.Bootstrap

"initialize-modules.ps1: install Chocolatey & basic packages Finish" | Write-Verbose
#endregion install Chocolatey & basic packages
     


#region install Git
"initialize-modules.ps1: install Git Start"  | Write-Verbose

<#
    $installGit = {
        Start-Transcript -path C:\bb\setup_transcript_git.txt -IncludeInvocationHeader -Append

        $Packages = Import-PowerShellDataFile c:\bb\packages.psd1
        . c:\bb\install-chocolateyPackages.ps1

        Install-ChocolateyPackage -package $Packages.chocolatey.Git

        Stop-Transcript
    }
    Start-Job -name installGit -scriptBlock $installGit
#>

    Install-ChocolateyPackage -package $Packages.chocolatey.Git

"initialize-modules.ps1: install Git Finish" | Write-Verbose
#endregion install Git



#region install Scoop
"initialize-modules.ps1: install scoop Start" | Write-Verbose

    function Install-ScoopPackage {

        [CmdletBinding(
            SupportsShouldProcess,
            PositionalBinding = $false,
            ConfirmImpact = 'Medium'
        )]

	    PARAM(
            [Parameter( Mandatory,
                Position = 0,
                HelpMessage = 'Enter the name of Scoop package',
                ValueFromPipeline,
                ValueFromPipelineByPropertyName )]
            [Alias( 'name', 'packageName' )]
            [ValidateScript({
                foreach ($parameter in $_) {
                    if( $parameter.GetType().Name -ne 'String' -and
                        $parameter.GetType().Name -ne 'Hashtable'
                    ) {
                        throw "Unknown argument type $( $parameter.GetType().Name )"
                    }

                    if( $parameter.GetType().Name -eq 'Hashtable' -and
                        'Name' -notIn $parameter.Keys 
                    ){
                        throw "Package name is missing in [$($parameter.Keys -join ', ')]"
                    }
                }
                return $True
            })]
		    [Object[]] 
            $package
	    )


        BEGIN {
            $allAttributes = 'Name', 'Options'
            $allOptions = , 'global'
        }
	
        PROCESS
        {
            $shouldProcess = $psCmdlet.ShouldProcess(
                "[$( $MyInvocation.MyCommand )] : Install packages from Scoop repositories",
                "Install package(s) [$($package -join ', ')] from Scoop repositories? ",
                '3rd party Software installation Warning!'
            )
            	        
            foreach ($1package in $package) 
            {
                $command = "scoop install" 

                if ($1package.GetType().Name -eq 'Hashtable')
                {
                    if ('Options' -in $1package.Keys)
                    {
                        # normalization: convert '  opTiOn1 ' and '-opTIOn2  ' to '--option1' and '--option2'
                        $normalizedOptions = $1package.options | 
                                ForEach-Object { 
                                    $_.Trim().ToLower() -replace '^-?\s*([^- ]+)$', '--$1' 
                                }

                        "Options: " | Write-Verbose; $normalizedOptions | Write-Verbose

                        foreach ($option in $normalizedOptions) 
                        {
                            if ( $option.Remove(0,2) -notIn $allOptions ) {
                                "Install-ScoopPackage(): Unknown option in $($1package.Name): '$option' " | Write-Warning
                            } else {
                                $command += ' ' + $option
                            }
                        }
                                        
                    } else {
                        $1package.options = @()
                    }
                    
                    $command += ' ' + $1package['name'].Trim()
                    if ($1package.Keys.Count -gt $allAttributes.Count) 
                    {
                        $unknownAttributes = $1package.Keys | ForEach-Object {
                            if ($_ -notIn $allAttributes) {
                                $_
                            }
                        }
                        "Install-ScoopPackage(): Unknown package attribute(s) in $($1package.Name): `'$( $unknownAttributes -join ', ')`' " | Write-Warning
                    } 
                }

                if ($shouldProcess) {
                    Invoke-Expression -command $command
                } else {
                    "Command to be executed: $command"
                }  
            }
        }

        END {}
    }


	$parameters = @{
		path = 		    'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
		name = 		    'SCOOP_GLOBAL' 
		propertyType = 	'ExpandString' 
		value = 	    "${ENV:PROGRAMDATA}\scoop"
	}
	New-ItemProperty @parameters -force

	Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh') -verbose

    scoop bucket add Extras
    scoop bucket add Nirsoft

    Install-ScoopPackage $Packages.Scoop

"initialize-modules.ps1: install scoop Finish" | Write-Verbose
#endregion install Scoop



#region install other packages
"initialize-modules.ps1: install other packages Start"  | Write-Verbose

    $installLight = {
        Start-Transcript -path C:\bb\setup_transcript_light.txt -IncludeInvocationHeader -Append

        $Packages = Import-PowerShellDataFile c:\bb\packages.psd1
        . c:\bb\install-chocolateyPackages.ps1

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
        . c:\bb\install-chocolateyPackages.ps1

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