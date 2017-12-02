function Install-ChocolateyPackage {
<#
        .SYNOPSIS
Installs packages from Chocolatey gallery with pipeline support and ability to pass advanced parameters individually to each package installer

        .DESCRIPTION
Installs packages from Chocolatey gallery with pipeline support and ability to pass advanced parameters individually to each package installer

        .INPUTS
[System.String[]], [System.Hashtable[]]

        .OUTPUTS
[System.Void]

        .PARAMETER Package
The names of package to install. Can be a single package or comma-separated list of packages.
In case of default install options only string name of package is required.
If you want to pass advanced install options to a package, use hashtable of the following structure instead:

@{
    Name =    'Package Name'
    Options = 'option1', 'optionN'
}

        .EXAMPLE
Install-ChocolateyPackage 7zip.install, NotepadPlusPlus.install

        .EXAMPLE
Install-ChocolateyPackage 7zip.install, @{ Name ='NotepadPlusPlus.install'; Options = '--x86' }

        .NOTES
(c) 2017 turboBasic https://github.com/turboBasic

        .LINK
https://github.com/turboBasic/

#>

    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false,
        ConfirmImpact = 'Medium'
    )]

	PARAM(
		[Parameter( Mandatory,
                    Position = 0,
                    HelpMessage = 'Enter the name of Chocolatey package',
                    ValueFromPipeline,
                    ValueFromPipelineByPropertyName )]
        [Alias( 'name', 'packageName' )]
        [ValidateScript({
            foreach ($parameter in $_) {
                if( $parameter.GetType().Name -ne 'String' -and
                    $parameter.GetType().Name -ne 'Hashtable'
                ){
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
        $allOptions = 'force', 'x86', 'ignorechecksum'
    }

    PROCESS
    {
        $packageList = $package | ForEach-Object { 
            $( if ($_.GetType().Name -eq 'Hashtable') 
               { $_.Name } 
               else 
               { $_ }
            )
        }
        $shouldProcess = $psCmdlet.ShouldProcess(
                "[$( $MyInvocation.MyCommand )] : Install packages from Chocolatey gallery",
                "Install package(s) [$packageList -join ', '] from Chocolatey gallery? ",
                '3rd party Software installation Warning!'
        )

	    foreach ($1package in $package) {
            $1package | Out-String | Write-Verbose

            if ($1package.GetType().Name -eq 'String') {
                $command = "Install-Package -provider ChocolateyGet -force -verbose -name $1package"
                $packageName = $1package
            }
            elseif ($1package.GetType().Name -eq 'Hashtable')
            {
                if ('Options' -in $1package.Keys) {
                    $command = "choco install --yes"     

                    # normalization: convert '  opTiOn1 ' and '-opTIOn2  ' to '--option1' and '--option2'
                    $normalizedOptions = $1package.options | 
                            ForEach-Object { 
                                $_.Trim().ToLower() -replace '^-?\s*([^- ]\S+)$', '--$1' 
                            }

                    "Options: " | Write-Verbose; $normalizedOptions | Write-Verbose

                    foreach ($option in $normalizedOptions) 
                    {
                        if ( $option.Remove(0,2) -notIn $allOptions ) {
                            "Install-ChocolateyPackage(): Unknown option in $($1package.Name): '$option' " | Write-Warning
                        } else {
                            $command += ' ' + $option
                        }
                    }                
                } else {
                    $command = "Install-Package -provider ChocolateyGet -force -verbose -name"
                    $1package.options = @()
                }                 

                $command += ' ' + $1package['name'].Trim()
                $packageName = $1package['name'].Trim()
                if ($1package.Keys.Count -gt $allAttributes.Count) 
                {
                    $unknownAttributes = $1package.Keys | ForEach-Object {
                        if ($_ -notIn $allAttributes) {
                            $_
                        }
                    }
                    "Install-ChocolateyPackage(): Unknown package attribute(s) in $($1package.Name): `'$( $unknownAttributes -join ', ')`' " | Write-Warning
                }
            }

            if ($shouldProcess) {
                if ($packageName -notIn (Get-Package -providerName ChocolateyGet).Name) {
                    Invoke-Expression -command $command
                } else {
                    "$packageName is already installed"| Write-Warning
                }
            } else {
                "Command to be executed: $command"
            }   
        }
    }

    END {}

}


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
                $command = 'scoop install'
                if ($1package.GetType().Name -eq 'String') {
                    $command += ' ' + $1package.Trim()
                }
                elseif ($1package.GetType().Name -eq 'Hashtable')
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


