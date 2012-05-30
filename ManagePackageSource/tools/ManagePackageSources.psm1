function Get-PackageSource {
    param(
		[parameter(Mandatory = $false)]
		[string]$Name
    )   
	
	$configuration = Get-Content "$env:AppData\NuGet\NuGet.config"
	$configurationXml = [xml]$configuration
	
	if ($Name -ne $null -and $Name -ne "") {
		return $configurationXml.configuration.packageSources.add | where { $_.key -eq $Name} | Format-Table @{Label="Name"; Expression={$_.key}}, @{Label="Source"; Expression={$_.value}}
	} else {
		return $configurationXml.configuration.packageSources.add | Format-Table @{Label="Name"; Expression={$_.key}}, @{Label="Source"; Expression={$_.value}}
	}
}

function Add-PackageSource {
    param(
		[parameter(Mandatory = $true)]
		[string]$Name,
		[parameter(Mandatory = $true)]
		[string]$Source
    )   

	$configuration = Get-Content "$env:AppData\NuGet\NuGet.config"
	$configurationXml = [xml]$configuration

	$sourceToAdd = $configurationXml.createElement("add")
	$sourceToAdd.SetAttribute("key", $Name);
	$sourceToAdd.SetAttribute("value", $Source);
	
	$configurationXml.configuration.packageSources.appendChild($sourceToAdd)
	
	$configurationXml.save("$env:AppData\NuGet\NuGet.config");
	
	return $Name
}

function Remove-PackageSource {
    param(
		[parameter(Mandatory = $true)]
		[string]$Name
    )   

	$configuration = Get-Content "$env:AppData\NuGet\NuGet.config"
	$configurationXml = [xml]$configuration

	$node = $configurationXml.SelectSingleNode("//packageSources/add[@key='$Name']")
	[Void]$node.ParentNode.RemoveChild($node)

	$configurationXml.save("$env:AppData\NuGet\NuGet.config");
}

function Set-ActivePackageSource {
    param(
		[parameter(Mandatory = $true)]
		[string]$Name
    )   

	$configuration = Get-Content "$env:AppData\NuGet\NuGet.config"
	$configurationXml = [xml]$configuration

	$node = $configurationXml.SelectSingleNode("//packageSources/add[@key='$Name']").clone()
	
	$activeNode = $configurationXml.SelectSingleNode("//activePackageSource")
	$activeNode.innerXML = ""
	$activeNode.appendChild($node)

	$configurationXml.save("$env:AppData\NuGet\NuGet.config");
}

Export-ModuleMember *