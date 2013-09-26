# NuGetPackages

Our collection of home-made NuGet packages :)

## NuSpec

Simply run Install-Package NuSpec (once for the solution, doesn't matter which project) to get a set of extra cmdlets available in the NuGet Package Manager Console.

Available cmdlets: *Install-NuSpec*, *Enable-NuSpecIntelliSense*

### Creating the package and auto-build

    Install-NuSpec <ProjectName> [-EnableIntelliSense] [-TemplatePath]
	
Adds a tokenized .nuspec file to the target project(s).
Use the <code>-EnableIntelliSense</code> swicth to add the nuspec.xsd to your Solution Items to provide IntelliSense.

### Done? Remove the dependency...

There's not much value in keeping the NuSpec package dependency around after setting up this automation, so feel free to simply remove it using *Uninstall-Package NuSpec*.
