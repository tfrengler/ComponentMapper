"use strict";

/*function getPos(e){
	var x=e.clientX;
	var y=e.clientY;
	var cursor="Your Mouse Position Is: X = " + x + " and Y = " + y ;
	console.log(cursor);
};*/

var main = {}; //Creating a namespace for our JS functionality
main.oCanvas = {};
main.oFamilyMap = undefined; //Filled by Coldfusion, converting a struct to a JS object

main.GetCanvas = function() {
	return this.oCanvas;
};

main.GetFamilyMap = function() {
	return this.oFamilyMap;
};

main.GetAmountOfChildren = function(ParentName) {
	var oFamilyMap = this.GetFamilyMap();
	var nReturnData = 0;

	if ( typeof oFamilyMap[ParentName] != "undefined" ) {
		nReturnData = oFamilyMap[ ParentName ].length;
	};

	return nReturnData;
};

main.GetDrawVectors = function(ElementStart, ElementEnd, Relationship) {
	// Gets us a list of vectors we want to draw lines between
	var aReturnData = [];

	if (Relationship == "ParentToParent") {
		aReturnData.push( this.GetDrawMarker(ElementStart, "left", 3, false) ); 	//Left side of parent, 3/4 down where the draw is to start
		aReturnData.push( this.GetDrawMarker(ElementStart, "left", 3, true) ); 	//Left side of parent, 3/4 and offset towards the left side of the document body

		aReturnData.push( this.GetDrawMarker(ElementEnd, "left", 1, false) );	//Left side of child of the parent, 1/4 down
		aReturnData[2][0] = aReturnData[1][0];					//Redirecting the X marker to be at the same horizontal point as the parent otherwise we get a diagonal line
		aReturnData.push( this.GetDrawMarker(ElementEnd, "left", 1, false) );	//Left side of child of the parent, 1/4 down where we want the draw to end
	}
	else if (Relationship == "ParentToChildren") {
		aReturnData.push( this.GetDrawMarker(ElementStart, "right", 1, false) );
		aReturnData.push( this.GetDrawMarker(ElementEnd, "left", 1, false) );
		aReturnData[1][1] = aReturnData[0][1]; //Redirecting the Y marker to be at the same vertical point as the start element otherwise we get a diagonal line
	};

	return aReturnData;
};

main.GetDrawMarker = function(Element, Side, Position, Offset) {
	/* Gets one set of draw coordinates (X,Y) for the given element, depending on side/position and offset
	 Currently supports getting a marker on the left or right side of an element between 1, 2, 3 or 4 quarters down (from the top of the element)
	 The offset is only used for the left side where we draw the lines between component parents */

	var aReturnData = [];
	var nMarkerX = NaN;
	var nMarkerY = NaN;
	var nRightSideCalculationBase = 100;
	var nLeftSideCalculationBase = 4;

	/* Need to get the canvas' position because its offset values will have to factored into the coordinates */
	var nCanvasOffsetLeft = this.GetCanvas().offsetLeft;
	var nCanvasOffsetTop = this.GetCanvas().offsetTop;

	var nElementLeft = Element.offsetLeft;
	var nElementTop = Element.offsetTop;
	var nElementHeight = Element.offsetHeight;
	var nElementWidth = Element.offsetWidth;

	if (Side == "left" ) {
		nMarkerY = nElementTop + ( (nElementHeight / nLeftSideCalculationBase) * Position ) - nCanvasOffsetTop;

		if (Offset == true) {
			nMarkerX = (nElementLeft / 100) * 50;;	
		}
		else {
			nMarkerX = nElementLeft - (nCanvasOffsetLeft + 1);
		};
	}
	else if (Side == "right" ) {
		nMarkerY = nElementTop + ( (nElementHeight / nRightSideCalculationBase ) * 5 ) - nCanvasOffsetTop;
		nMarkerX = nElementLeft + (nElementWidth - nCanvasOffsetLeft);
	};

	aReturnData.push(nMarkerX);
	aReturnData.push(nMarkerY);

	return aReturnData;
};

main.TracePathAndDrawLine = function(ComponentNameStart, ComponentNameEnd, Relationship) {
	// Traces a path between a set of vectors and then draws a line

	var oCanvas = this.GetCanvas();
	var oBrush = oCanvas.getContext("2d");

	oBrush.lineWidth = 3;
	oBrush.lineJoin = "round";
	oBrush.lineCap = "square";
	oBrush.strokeStyle = "#5990ea";

	var sComponentNameEnd = "";
	var aCurrentVector = [];

	if (Relationship == "ParentToParent") {
		sComponentNameEnd = ComponentNameEnd;
	}
	else if (Relationship == "ParentToChildren") {
		sComponentNameEnd = "Children-" + ComponentNameEnd;
	};

	var oStartElement = document.getElementById(ComponentNameStart);
	var oEndElement = document.getElementById(sComponentNameEnd);

	if (oStartElement == null || oEndElement == null) {
		return false;
	};

	var aDrawVectors = this.GetDrawVectors(oStartElement, oEndElement, Relationship);
	if (aDrawVectors.length == 0) {
		return false;
	};

	oBrush.beginPath(); // Clears current paths, if there are any in the canvas

	for (var i = 0; i < aDrawVectors.length; i++) {
		aCurrentVector = aDrawVectors[i];

		if (i == 0) {
			oBrush.moveTo(aCurrentVector[0], aCurrentVector[1]);	// moveTo sets the coordinates of the start of a path
		}
		else {
			oBrush.lineTo(aCurrentVector[0], aCurrentVector[1]); // Moves the path to provided coordinates
		};	
	};
	oBrush.stroke(); // All paths have been traced and now we stroke/draw straight lines between them

	return true;
};

main.DrawFamilyTree = function() {
	// Main function that loops through the family map and calls TracePathAndDrawLine() for each relationship to draw inheritance lines between them

	var oFamilyMap = this.GetFamilyMap();
	// In case the family map is not ready (a huge inheritance chain could cause this) the function checks and then sets a timeout to call itself again
	if (typeof this.GetFamilyMap() == "undefined") {
		window.setTimeOut(main.DrawFamilyTree, 3000);
		return false;
	};

	var oCanvas = this.GetCanvas();
	var oBrush = oCanvas.getContext("2d");
	oBrush.clearRect(0, 0, oCanvas.width, oCanvas.height);  //Clear the current lines from the canvas in case there are any (for browser resizing)

	var sComponentName = "";
	var aComponentChildren = [];
	var nNumberOfChildren = 0;
	var sChildName = "";

	for (sComponentName in oFamilyMap) {

		aComponentChildren = oFamilyMap[sComponentName];
		nNumberOfChildren = aComponentChildren.length;

		for (var i = 0; i < nNumberOfChildren; i++) {
			sChildName = aComponentChildren[i].toLowerCase(); // Sighing at CF and its tendency to NOT preserve struct keys case when converting to JS...

			if ( typeof oFamilyMap[sChildName] != "undefined" ) {
				this.TracePathAndDrawLine(sComponentName, sChildName, "ParentToParent");
			};
		};

		this.TracePathAndDrawLine(sComponentName, sComponentName, "ParentToChildren");
	};

	return true;
};

main.GetMethodData = function(ComponentName, MethodName) {
	main.DestroyDialog(); // Removes existing dialog. If the user clicks another method while an existing dialog is open then the close() method is not invoked on the dialog

	var oDialog = document.createElement("div");
	oDialog.setAttribute("id", "MethodDataDialog"); 
	oDialog.setAttribute("title", ComponentName + "." + MethodName);

	document.getElementsByTagName("body")[0].appendChild(oDialog);

	var RequestParameters = "?ComponentName=" + ComponentName.trim() + "&MethodName=" + MethodName.trim();
	$("#MethodDataDialog").load(
		"GetCFCData.cfm" + RequestParameters
	);

	$("#MethodDataDialog").dialog({
		width: 600,
		close: main.DestroyDialog,
		position: { my: "center", at: "top", of: document.getElementById( ComponentName.toLowerCase() ) }	
	});
};

main.DestroyDialog = function() {

	$("#MethodDataDialog").dialog("destroy");

	var oDialog = document.getElementById("MethodDataDialog");
	if (oDialog == null) {
		return false;
	}
	else {
		document.getElementsByTagName("body")[0].removeChild(oDialog);	
	};

	return true;
};

main.init = function() {

	var oCanvas = document.getElementById('DrawingBoard');
	var nDocumentHeight = document.getElementsByTagName('body')[0].offsetHeight;
	var nDocumentWidth = document.getElementsByTagName('body')[0].offsetWidth;

	oCanvas.height = nDocumentHeight;
	oCanvas.width = nDocumentWidth;

	this.oCanvas = oCanvas;
	this.DrawFamilyTree();

	window.onresize = function() {
		main.DrawFamilyTree(); //Need to redraw the canvas lines when the window is resized otherwise they no longer line up
	};
};