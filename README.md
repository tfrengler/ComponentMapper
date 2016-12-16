# ComponentMapper
A Coldfusion CFC mapping utility

This tool parses a folder with components, reads them and uses their metadata to construct a flowchart-like visual map. It lists each CFC - with their properties and methods - and draws inheritance lines between them. In addition you can click on each method to get a jQuery dialog that gives basic information about the method such as a list of the different arguments, return type, access etc. The goal with this mapper was to create something that could create a similar map that you'd normally see in a PDF or an MS Visio-document, but have it be dynamic so that you don't ever have to manually maintain a document yourself. Although initially created as automated documentation for the webservices it has been developed and tested on our regular components folder. The only limitation I can think of right now is that it can't map a component structure spread across various folders - it can only read and create a map of components from one folder.

Everything is encased in functions and scoped properly so this page will not leave any traces behind in the global scope. Most of the stuff you may want to modify (what directory of CFCs to target) is in the init()-function down near the bottom. The bits you want to be mindful of are these:

<cfset var sDirectory = "" />

<cfset var stBuildComponentMetadataCollectionRet = BuildComponentMetadataCollection(
	ComponentDirectory=sDirectory,
	ComponentMapping=""
) />

The ComponentDirectory is the folder where the CFCs live and is used by cfdirectory to read and list the available components. BuildComponentMetadataCollection() will by default try to instantiate the components from the folder where this cfm-file is. If you want to give it a different target you have to pass a mapping via ComponentMapping (NOTE: you must include a trailing dot!)
