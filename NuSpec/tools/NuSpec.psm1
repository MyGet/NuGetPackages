function Get-SolutionDir {
    if($dte.Solution -and $dte.Solution.IsOpen) {
        return Split-Path $dte.Solution.Properties.Item("Path").Value
    }
    else {
        throw "Solution not avaliable"
    }
}

function Resolve-ProjectName {
    param(
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [string[]]$ProjectName
    )
    
    if($ProjectName) {
        $projects = Get-Project $ProjectName
    }
    else {
        # All projects by default
        $projects = Get-Project -All
    }
    
    $projects
}

function Get-MSBuildProject {
    param(
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [string[]]$ProjectName
    )
    Process {
        (Resolve-ProjectName $ProjectName) | % {
            $path = $_.FullName
            @([Microsoft.Build.Evaluation.ProjectCollection]::GlobalProjectCollection.GetLoadedProjects($path))[0]
        }
    }
}

function Set-MSBuildProperty {
    param(
        [parameter(Position = 0, Mandatory = $true)]
        $PropertyName,
        [parameter(Position = 1, Mandatory = $true)]
        $PropertyValue,
        [parameter(Position = 2, ValueFromPipelineByPropertyName = $true)]
        [string[]]$ProjectName
    )
    Process {
        (Resolve-ProjectName $ProjectName) | %{
            $buildProject = $_ | Get-MSBuildProject
            $buildProject.SetProperty($PropertyName, $PropertyValue) | Out-Null
            $_.Save()
        }
    }
}

function Get-MSBuildProperty {
    param(
        [parameter(Position = 0, Mandatory = $true)]
        $PropertyName,
        [parameter(Position = 2, ValueFromPipelineByPropertyName = $true)]
        [string]$ProjectName
    )
    
    $buildProject = Get-MSBuildProject $ProjectName
    $buildProject.GetProperty($PropertyName)
}

function Install-NuSpec {
    param(
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [string[]]$ProjectName,
    	[switch]$EnablePackageBuild,
        [string]$TemplatePath
    )
    
    Process {
    
        $projects = (Resolve-ProjectName $ProjectName)
        
        if(!$projects) {
            Write-Error "Unable to locate project. Make sure it isn't unloaded."
            return
        }
		
		$profileDirectory = Split-Path $profile -parent
		$profileModulesDirectory = (Join-Path $profileDirectory "Modules")
		$moduleDir = (Join-Path $profileModulesDirectory "NuSpec")
		
        $solutionDir = Get-SolutionDir
        $solution = Get-Interface $dte.Solution ([EnvDTE80.Solution2])
                    
        # Set up solution folder "Solution Items"
        $solutionItemsProject = $dte.Solution.Projects | Where-Object { $_.ProjectName -eq "Solution Items" }
        if(!($solutionItemsProject)) {
            $solutionItemsProject = $solution.AddSolutionFolder("Solution Items")
        }        
        
        # Copy the XSD's in the solution directory
        'nuspec.2010.7.xsd', 'nuspec.2011.8.xsd' | % {
            $nuspecXsd = $_
            
            try {
                $xsdInstallPath = Join-Path $solutionDir $nuspecXsd
                $xsdToolsPath = Join-Path $moduleDir $nuspecXsd
                
                if(!(Test-Path $xsdInstallPath)) {
                    Copy-Item $xsdToolsPath $xsdInstallPath
                }
                
                $alreadyAdded = $solutionItemsProject.ProjectItems | Where-Object { $_.Name -eq $nuspecXsd }
                if(!($alreadyAdded)) {
                    $solutionItemsProject.ProjectItems.AddFromFile($xsdInstallPath) | Out-Null
                }
            }
            catch {
                Write-Warning "Failed to install nuspec XSD '$nuspecXsd' into 'Solution Items'"
            }
        }
        $solution.SaveAs($solution.FullName)
        
        # Add NuSpec file for project(s)
        $projects | %{ 
            $project = $_
            
            # Set the nuspec target path
            $projectFile = Get-Item $project.FullName
            $projectDir = [System.IO.Path]::GetDirectoryName($projectFile)
            $projectNuspec = "$($project.Name).nuspec"
            $projectNuspecPath = Join-Path $projectDir $projectNuspec
            
            # Get the nuspec template source path
            if($TemplatePath) {
                $nuspecTemplatePath = $TemplatePath
            }
            else {
                $nuspecTemplatePath = Join-Path $moduleDir NuSpecTemplate.xml
            }
            
            # Copy the templated nuspec to the project nuspec if it doesn't exist
            if(!(Test-Path $projectNuspecPath)) {
                Copy-Item $nuspecTemplatePath $projectNuspecPath
            }
            else {
                Write-Warning "Failed to install nuspec '$projectNuspec' into '$($project.Name)' because the file already exists."
            }
            
            try {
                # Add nuspec file to the project
                $project.ProjectItems.AddFromFile($projectNuspecPath) | Out-Null
                $project.Save()
				
				Set-MSBuildProperty NuSpecFile $projectNuspec $project.Name
                
                "Updated '$($project.Name)' to use nuspec '$projectNuspec'"
            }
            catch {
                Write-Warning "Failed to install nuspec '$projectNuspec' into '$($project.Name)'"
            }
			
			# Enable package build if switch is provided
			if($EnablePackageBuild) {
				Set-MSBuildProperty BuildPackage true $project.Name
			}
        }
    }
}

function Enable-PackagePush {
	param(
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [string[]]$ProjectName
	)
	
	Process {
		$projects = (Resolve-ProjectName $ProjectName)
        
        if(!$projects) {
            Write-Error "Unable to locate project. Make sure it isn't unloaded."
            return
        }
		
		$profileDirectory = Split-Path $profile -parent
		$profileModulesDirectory = (Join-Path $profileDirectory "Modules")
		$moduleDir = (Join-Path $profileModulesDirectory "NuSpec")
		$solutionDir = Get-SolutionDir
		$nugetFolder = Join-Path $solutionDir .nuget
		
		if(!(Test-Path $nugetFolder)) {
			Write-Error "The '$nugetFolder' doesn't exist. Please enable package restore before using this feature."
		}
		else {
			# Copy NuGet.Extensions.targets to $(SolutionDir)\.nuget folder
			$nugetExtensionsSrcPath = Join-Path $moduleDir NuGet.Extensions.targets
			Copy-Item $nugetExtensionsSrcPath $nugetFolder
			
			# Copy MSBuildExtensionPack to $(SolutionDir)\.nuget\MSBuildExtensionPack folder
			$msbuildExtensionPackSrcPath = Join-Path $moduleDir MSBuildExtensionPack
			$msbuildExtensionTargetPath = Join-Path $nugetFolder MSBuildExtensionPack
			if(!(Test-Path $nugetFolder)) {
				New-Item $msbuildExtensionTargetPath -type directory
			}			
			Copy-Item $msbuildExtensionPackSrcPath $msbuildExtensionTargetPath -recurse -force
			
			# Modify nuget.targets file
			$nugetTargetsPath = Join-Path $nugetFolder nuget.targets
			$alreadyRegistered = Select-String -Path $nugetTargetsPath -Pattern "NuGet.Extensions.targets"
			if(!($alreadyRegistered)){
				$doc = [xml](Get-Content -Path $nugetTargetsPath)
				$propertyGroup = $doc.Project.PropertyGroup
				
				# Import nuget.extensions.targets
				$importExtensionsElement = $doc.CreateElement("Import")
				$importExtensionsElement.SetAttribute("Project", "NuGet.Extensions.targets")
				$doc.Project.InsertAfter($importExtensionsElement, $propertyGroup) | Out-Null
				
				# Add commands to BuildPackage target
				$buildPackageTarget = $doc.Project.Target | where { $_.Name -eq "BuildPackage" }
				$buildPackageTarget.SetAttribute("DependsOnTargets", "CheckPrerequisites; SetPackageVersion")
				
				$pushCommand = $doc.CreateElement("Exec")
				$pushCommand.SetAttribute("Command", "`$(PushCommand)")
				$pushCommand.SetAttribute("LogStandardErrorAsError", "true")
				$pushCommand.SetAttribute("Condition", "Exists('`$(NuPkgFile)') And `$(PushPackage) == 'true'")
				$buildPackageTarget.AppendChild($pushCommand) | Out-Null
				
				$pushSymbolsCommand = $doc.CreateElement("Exec")
				$pushSymbolsCommand.SetAttribute("Command", "`$(PushSymbolsCommand)")
				$pushSymbolsCommand.SetAttribute("LogStandardErrorAsError", "true")
				$pushSymbolsCommand.SetAttribute("Condition", "Exists('`$(SymbolsPkgFile)') And `$(PushPackage) == 'true'")
				$buildPackageTarget.AppendChild($pushSymbolsCommand) | Out-Null
				
				# Save the changes
				$doc = [xml]$doc.OuterXml.Replace(" xmlns=`"`"", "")
				$doc.Save($nugetTargetsPath) | Out-Null
				
				# Add the new targets files to the .nuget solution folder
				$solution = Get-Interface $dte.Solution ([EnvDTE80.Solution2])
				$solutionItemsProject = $dte.Solution.Projects | Where-Object { $_.ProjectName -eq ".nuget" }
				if(!($solutionItemsProject)) {
					$solutionItemsProject = $solution.AddSolutionFolder(".nuget")
				}
				$nugetExtensionsTargetsFile = Join-Path $nugetFolder NuGet.Extensions.targets
				$alreadyAdded = $solutionItemsProject.ProjectItems | Where-Object { $_.Name -eq $nugetExtensionsTargetsFile }
                if(!($alreadyAdded)) {
                    $solutionItemsProject.ProjectItems.AddFromFile($nugetExtensionsTargetsFile) | Out-Null
                }
				$solution.SaveAs($solution.FullName) | Out-Null
			}
			
			# Set the PushPackage MSBuild property to true for the target project(s)
			$projects | %{ 
				$project = $_
				Set-MSBuildProperty BuildPackage true $project.Name
				Set-MSBuildProperty PushPackage true $project.Name
				Write-Host "Enabled Package Push for project '$($project.Name)'"
			}
		}
	}
}

# Statement completion for project names
'Install-NuSpec', 'Enable-PackagePush' | %{ 
    Register-TabExpansion $_ @{
        ProjectName = { Get-Project -All | Select -ExpandProperty Name }
    }
}

Export-ModuleMember Install-NuSpec, Enable-PackagePush