# ComponentMapper
A Coldfusion CFC mapping utility

This tool parses a folder with components, reads them and uses their metadata to construct a flowchart-like visual map. It lists each CFC - with their properties and methods - and draws inheritance lines between them. In addition you can click on each method to get a jQuery dialog that gives basic information about the method such as a list of the different arguments, return type, access etc. 

The goal with this mapper was to create something that could create a similar map that you'd normally see in a PDF or an MS Visio-document, but have it be dynamic so that you don't ever have to manually maintain a document yourself. Although initially created as automated documentation for our webservices it has was developed and tested against our regular components folder as well.

Everything is encased in functions and (should be) scoped properly so this page will not leave any traces behind in the global scope.

NOTES ON USAGE/LIMITATIONS:

The only limitation I can think of right now is that it can't map a component structure spread across various folders - it can only read and create a map of components from one folder.

Drawing the inheritance lines between the components is done with Javascript, using Canvas. So if you're using a browser that doesn't support canvas then the lines obviously won't be drawn. This was my first time ever using canvas so forgive me if it isn't perfect.

If the code offends anyone's syntax or convention-sensibilities then I apologize. I am a tester by trade and have no formal education programming (completely self-taught). The code is a straight copy of the version we use at work and variable names etc. are all adhering to our coding standards.
