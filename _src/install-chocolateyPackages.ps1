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
        $allOptions = 'force', 'x86', 'ignorechecksum'
    }

    PROCESS
    {
        $shouldProcess = $psCmdlet.ShouldProcess(
                "[$( $MyInvocation.MyCommand )] : Install packages from Chocolatey gallery",
                "Install package(s) [$($package -join ', ')] from Chocolatey gallery? ",
                '3rd party Software installation Warning!'
        )

	    foreach ($1package in $package) {
            $1package | Out-String | Write-Verbose
            if ($1package.GetType().Name -eq 'String') {
                $command = "Install-Package -provider ChocolateyGet -force -verbose -name $1package"
            }
            elseif ($1package.GetType().Name -eq 'Hashtable')
            {
                if ('Options' -in $1package.Keys) {
                    $command = "choco install --yes"     

                    # normalization: convert '  opTiOn1 ' and '-opTIOn2  ' to '--option1' and '--option2'
                    $normalizedOptions = $1package.options | 
                            ForEach-Object { 
                                $_.Trim().ToLower() -replace '^-?\s*([^- ]+)$', '--$1' 
                            }

                    "Options: " | Write-Verbose; $normalizedOptions | Write-Verbose

                    foreach ($option in $normalizedOptions) 
                    {
                        if ( $option.Remove(0,2) -notIn $allOptions ) {
                            "Install-ChocolateyPackages(): Unknown option in $($1package.Name): '$option' " | Write-Warning
                        } else {
                            $command += ' ' + $option
                        }
                    }                
                } else {
                    $command = "Install-Package -provider ChocolateyGet -force -verbose -name"
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
                    "Install-ChocolateyPackages(): Unknown package attribute(s) in $($1package.Name): `'$( $unknownAttributes -join ', ')`' " | Write-Warning
                }
            }

            # Install-Package -name $_ -provider ChocolateyGet -force -verbose
            #Invoke-Expression -command $command
            if ($shouldProcess) {
                Invoke-Expression -command $command
            } else {
                "Command to be executed: $command"
            }   
        }
    }

    END {}
