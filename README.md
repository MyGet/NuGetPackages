# NuGetPackages

My collection of home-made NuGet packages :)

## NuSpec

Simply run Install-Package NuSpec (once for the solution, doesn't matter which project) to get a set of extra cmdlets available in the NuGet Package Manager Console.
The cmdlets in this package rely on the NuGet "Enable Package Restore" feature, which adds a .nuget folder in the solution directory containing the nuget.exe command line tool and nuget.targets MSBuild file.

Available cmdlets: *Install-NuSpec*, *Enable-PackagePush*

### Creating the package and auto-build

    Install-NuSpec <ProjectName> [-EnablePackageBuild]
	
Adds a tokenized .nuspec file to the target project(s).
Use the <code>-EnablePackageBuild</code> swicth to automatically build the nuget package when building the project.

### Auto-pushing the package and symbols

    Enable-PackagePush <ProjectName>

Will install a <code>NuGet.Extensions.targets</code> MSBuild file and set the <code>&lt;PushPackage&gt;true&lt;/PushPackage&gt;</code> MSBuild property in the target project(s). 

You can tweak **package versioning** in the <code>MSBuild.ExtensionPack.VersionNumber.targets</code> file, located under <code>$(SolutionDir)\.nuget\MSBuildExtensionPack</code>.
*This is based on the MSBuild ExtensionPack SetVersionNumber target.*

**Don't forget** to set the target feed URL for the packages and symbols, including the API key, in the <code>NuGet.Extensions.targets</code> file.

### Done? Remove the dependency...

There's not much value in keeping the NuSpec package dependency around after setting up this automation, so feel free to simply remove it using *Uninstall-Package NuSpec*.