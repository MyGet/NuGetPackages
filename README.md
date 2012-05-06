# NuGetPackages

My collection of home-made NuGet packages :)

## NuSpec

Simply run Install-Package NuSpec to get a set of extra cmdlets available in the NuGet Package Manager Console.
The cmdlets in this package rely on the NuGet "Enable Package Restore" feature, which adds a .nuget folder in the solution directory containing the nuget.exe command line tool and nuget.targets MSBuild file.

Available cmdlets: *Install-NuSpec*, *Enable-PackagePush*

### Creating the package and auto-build

    Install-NuSpec
	
Adds a tokenized .nuspec file to the target project(s).
Use the <code>-EnablePackageBuild</code> swicth to automatically build the nuget package when building the project.

### Auto-pushing the package and symbols

    Enable-PackagePush

Will install a <code>NuGet.Extensions.targets</code> MSBuild file and set the <code>&lt;PushPackage&gt;true&lt;/PushPackage&gt;</code> MSBuild property in the target project(s). 
You can tweak package versioning in the <code>$(SolutionDir)\.nuget\MSBuildExtensionPack\MSBuild.ExtensionPack.VersionNumber.targets</code> file. 
In the <code>NuGet.Extensions.targets</code> file you can also tweak the target NuGet repository to indicate where the built NuGet package and symbols package need to be pushed.