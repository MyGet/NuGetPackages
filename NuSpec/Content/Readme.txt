The Install-NuSpec cmdlet generates tokenized .nuspec manifest files 
within the target projects using the latest NuGet manifest XSD in the XML-namespace,
which ensures you can benefit from the latest packaging features.

If desired, you can change the XML-namespace and target the original XSD.
To do so, replace the current package declaration by the following:

<package xmlns="http://schemas.microsoft.com/packaging/2010/07/nuspec.xsd">

Run "nuget.exe pack <project>" to build a nuget package for this project
(which will also use the metadata from the tokenized nuspec file in the project directory).