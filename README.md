NuGetPackages
=============

My collection of home-made NuGet packages :)

NuSpec
------
Simply run Install-Package NuSpec to get a set of extra cmdlets available in the NuGet Package Manager Console.
The cmdlets in this package rely on the NuGet "Enable Package Restore" feature, which adds a .nuget folder in the solution directory containing the nuget.exe command line tool and nuget.targets MSBuild file.

Available cmdlets:
- *Install-NuSpec*: Adds a tokenized .nuspec file to the target project(s). Use the -EnablePackageBuild switch to automatically build the nuget package when building the project.
- *Enable-PackagePush*: This will install a NuGet.Extensions.Targets MSBuild file and set the <PushPackage>true</PushPackage> MSBuild property in the target project(s). You can tweak package versioning in the $(SolutionDir)\.nuget\MSBuildExtensionPack\MSBuild.ExtensionPack.VersionNumber.targets file. In the NuGet.Extensions.targets file you can also tweak the target NuGet repository to indicate where the built NuGet package and symbols package need to be pushed.