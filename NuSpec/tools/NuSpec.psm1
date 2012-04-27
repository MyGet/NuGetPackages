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

function Install-NuSpec {
    param(
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [string[]]$ProjectName
    )
    
    Process {
    
        if($ProjectName) {
            $projects = Get-Project $ProjectName
        }
        else {
            # All projects by default
            $projects = Get-Project -All
        }
        
        if(!$projects) {
            Write-Error "Unable to locate project. Make sure it isn't unloaded."
            return
        }
        
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
                $xsdToolsPath = Join-Path $global:nuspecToolsPath $nuspecXsd
                
                if(!(Test-Path $xsdInstallPath)) {
                    Copy-Item $xsdToolsPath $xsdInstallPath
                }
                
                # TODO: check if solution item already exists
                $alreadyAdded = $slnFolder.ProjectItems | Where-Object { $_.Name -eq $nuspecXsd }
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
            $nuspecTemplatePath = Join-Path $global:$nuspecToolsPath NuSpecTemplate.xml
            
            # Copy the templated nuspec to the project nuspec if it doesn't exist
            if(!(Test-Path $projectNuspecPath)) {
                Copy-Item $nuspecTemplatePath $projectNuspecPath
            }
            else {
                Write-Warning "Failed to install nuspec '$projectNuspec' into '$($project.Name)' because the file already exists."
            }
            
            try {
                $project.ProjectItems.AddFromFile($projectNuspecPath) | Out-Null
                $project.Save()
                
                "Updated '$($project.Name)' to use nuspec '$projectNuspec'"
            }
            catch {
                Write-Warning "Failed to install nuspec '$projectNuspec' into '$($project.Name)'"
            }
        }
    }
}

# Statement completion for project names
'Install-NuSpec' | %{ 
    Register-TabExpansion $_ @{
        ProjectName = { Get-Project -All | Select -ExpandProperty Name }
    }
}

Export-ModuleMember Install-NuSpec