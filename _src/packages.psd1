@{

    chocolatey = @{

        Bootstrap = @(

            # Compression/decompression utilities
                '7zip.install', 
                '7zip.commandline'
        )

        Git = @(
            # Git for Windows                 
                'Git.install'                                   
        )

        Light =  @(

            # Registry, Environment, System Management utilities
	            'Rapidee',                                      
                'RegistryManager', 
                'SystemExplorer',

            # Shells, Terminals and Launchers
	            'CmderMini',                         		    
                'Keypirinha', 
                'DoubleCmd',
	            'LinkShellExtension', 
                'Putty',

            # Text editors, finders and organizers
	            @{   
                    Name = 'NotepadPlusPlus.install'    
                    Options = '--x86' 
                },
                'Everything',

            # Internet
	            'QbitTorrent', 
    
            # Media viewers / Managers              	    
	            'SumatraPDF.install', 
                'Vlc',     		        
	            'Foobar2000', 
                'Fsviewer'
        )


        Extra =  @(

            # Runtime environments, libraries and frameworks
	            'VCredist-All', 
                'JavaRuntime',
    
            # Registry, Environment, System Management utilities 			        
	            'Rufus', 
                'SysInternals',

            # Shells, Terminals and Launchers		                
	            'DoubleCmd', 
                'Streams',
    
            # Internet
                'Chromium',

            # Text editors, finders and organizers      	                
	            'Ditto.install',

            # Media viewers / Managers  			                    
	            'Calibre', 
                'Dropbox',
    
            # Development IDEs     	                    
	            'Webstorm', 
                'Phpstorm',
    
            # Development tools                     	
	            'Kdiff3', 
                'WinSCP.portable', 
                'Lepton', 
                'jq',
                'zeal',
                'devdocs-app' 	
        )
    }

    scoop = @{

        Basic = @(

            # Registry, Environment, System Management utilities	
                @{ 
                    Name =      'which'
                    Options =   'global'
                },
                @{ 
                    Name =      'sudo'
                    Options =   'global' 
                },

            # Nirsoft utilities
	            'Filetypesman', 
                'ShellExView',
	            'ShellMenuView', 
                'RegDllView',
	            'OpenedFilesView'
        )

        Extra = @(
        
            @{
                Name =      'firefox-developer'                Options =   'global'
            }
        
        )

    }

}