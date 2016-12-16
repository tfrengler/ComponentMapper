<cfprocessingdirective pageencoding="utf-8" />

<!---

A note on naming conventions: I made up my own list of names for various levels of family relationships CFCs can have. They probably differ from programming standards or normal conventions but in the context of how this function works to render the family tree (working from the top and down the inheritance line, rather than the traditional programmatic "extends", which goes up) it made more sense to me. Crucially it provided a sane way of differentiating the different relationships in order to keep track of how to render it on screen.

FAMILY RELATIONS OF COMPONENTS:

Patriarchs (CFCs with children but no parents)
Parents (CFCs with parents and children)
Children (CFCs with parents but no children)
Orphans (CFCs with no parents or children)

--->

<!--- BACKEND DATA FETCHING/BUILDING FUNCTIONS --->

<cffunction name="BuildComponentMetadataCollection" returntype="struct" access="public" hint="Builds a struct with two keys: one with the metadata of the components it finds. The other with an array of objects that for whatever reason couldn't be instantiated and the reason why" output="true" >

	<cfargument name="ComponentDirectory" type="string" required="true" hint="The folder that will be used to loop over and get the actual list of cfc-files to work with" />
	<cfargument name="ComponentMapping" type="string" required="false" default="" hint="By default the components will be instantiated from the folder that this file is in. If you want to instantiate them from somewhere else then you pass the mapping (defined in the appropriate Application.cfc) that it should use. NOTE: Must contain a trailing dot. Example: Webservices.v11." />

	<cfset var stReturnData.stMetadata = structNew() />
	<cfset stReturnData.aFailedInstantiations = arrayNew(1) />
	<cfset var qComponentList = queryNew("") />
	<cfset var stFailedInstantiationDetails = structNew() />
	<cfset var sComponentName = "" />
	<cfset var oComponentInstance = "" />
	<cfset var oComponentMetaData = "" />

	<cfdirectory action="list" directory="#arguments.ComponentDirectory#" name="qComponentList" filter="*.cfc" />

	<cfloop query="qComponentList" >

		<cftry>
			<cfset sComponentName = listFirst(qComponentList.Name, ".") />
			<cfset oComponentInstance = createObject("component", "#arguments.ComponentMapping##sComponentName#") />
			<cfset oComponentMetaData = GetMetaData(oComponentInstance) />

		<cfcatch>
			<cfset stFailedInstantiationDetails = structNew() />
			<cfset structInsert(stFailedInstantiationDetails, "Component", sComponentName) />
			<cfset structInsert(stFailedInstantiationDetails, "Reason", cfcatch.detail) />
			<cfset arrayAppend(stReturnData.aFailedInstantiations, stFailedInstantiationDetails) />

		</cfcatch>
		</cftry>

		<cfif structKeyExists(stReturnData.stMetadata, "#sComponentName#") EQ false >
			<cfset structInsert(stReturnData.stMetadata, sComponentName, oComponentMetaData) />
		</cfif>
	</cfloop>

	<cfreturn stReturnData />
</cffunction>

<cffunction name="BuildFamilyMap" returntype="struct" access="public" hint="Returns a struct with the names of components that are parents as keys. Each key has an array of component names that inherit from that component" >

	<cfargument name="ComponentCollection" type="struct" required="true" hint="A struct with the component names as keys. Each key must have the metadata of the component" />

	<cfset var stInheritanceMap = structNew() />
	<cfset var sParentCFCName = "" />
	<cfset var stCurrentCFC = structNew() />
	<cfset var sCurrentComponentCollectionIndex = "" />

	<cfloop collection="#arguments.ComponentCollection#" item="sCurrentComponentCollectionIndex" >
		<cfset stCurrentCFC = arguments.ComponentCollection[sCurrentComponentCollectionIndex] />

		<!--- WEB-INF contains the base "components.cfc" that all CFCs inherit from so will exclude that as we don't want that in our mapping --->
		<cfif isDefined("stCurrentCFC.Extends") AND find("WEB-INF", stCurrentCFC.Extends.FullName) IS 0 >

			<cfset sParentCFCName = listLast(stCurrentCFC.Extends.FullName, ".") />

			<cfif structKeyExists(stInheritanceMap, sParentCFCName) IS false >
				<cfset stInheritanceMap[sParentCFCName] = arrayNew(1) />
			</cfif>

			<cfset arrayAppend(stInheritanceMap[sParentCFCName], sCurrentComponentCollectionIndex ) />
		</cfif>
	</cfloop>

	<cfreturn stInheritanceMap />
</cffunction>

<cffunction name="BuildListOfPatriarchs" returntype="array" access="public" hint="Returns an array of names of components that are patriarchs" >

	<cfargument name="FamilyMap" type="struct" required="true" hint="A struct with the names of components that are parents as keys. Each key should have an array of component names that inherit from that component" />

	<cfset var sCFCBeingCheckedForTopLevel = "" />
	<cfset var sCFCParentBeingInpected = "" />
	<cfset var bIsTopLevelParent = true />
	<cfset var aListOfPatriarchs = arrayNew(1) />

	<cfloop collection="#arguments.FamilyMap#" item="sCFCBeingCheckedForTopLevel" >

		<cfset bIsTopLevelParent = true />

		<cfloop collection="#arguments.FamilyMap#" item="sCFCParentBeingInpected" >

			<cfif arrayFind(arguments.FamilyMap[sCFCParentBeingInpected], sCFCBeingCheckedForTopLevel) GT 0 >
				<cfset bIsTopLevelParent = false />
				<cfbreak />
			</cfif>

		</cfloop>

		<cfif bIsTopLevelParent IS true >
			<cfset arrayAppend(aListOfPatriarchs, sCFCBeingCheckedForTopLevel) />
		</cfif>	

	</cfloop>

	<cfreturn aListOfPatriarchs />
</cffunction>

<cffunction name="BuildListOfOrphans" returntype="array" access="public" hint="Returns an array with names of components that don't inherit and are not inherited from" >

	<cfargument name="ComponentCollection" type="struct" required="true" hint="A struct with component names as keys. Each key must contain the metadata of that component" />
	<cfargument name="FamilyMap" type="struct" required="true" hint="A struct with the names of components that are parents as keys. Each key should have an array of component names that inherit from that component" />

	<cfset var aOrphanList = arrayNew(1) />
	<cfset var sCFCBeingCheckedForOrphanStatus = "" />
	<cfset var bHasFamily = false />
	<cfset var sCurrentParentCFC = "" />

	<cfloop collection="#arguments.ComponentCollection#" item="sCFCBeingCheckedForOrphanStatus" >
		<cfset bHasFamily = false />

		<cfif structKeyExists(arguments.FamilyMap, sCFCBeingCheckedForOrphanStatus) EQ true >
			<!--- Current CFC is a parent and thus not an orphan, skip and start next iteration --->
			<cfcontinue/>
		</cfif>

		<cfloop collection="#arguments.FamilyMap#" item="sCurrentParentCFC" >
			<cfif arrayFind(arguments.FamilyMap[sCurrentParentCFC], sCFCBeingCheckedForOrphanStatus) GT 0 >
				<!--- Current CFC is a child and thus not an orphan, set flag--->
				<cfset bHasFamily = true />
			</cfif>
		</cfloop>

		<cfif bHasFamily IS false >
			<cfset arrayAppend(aOrphanList, sCFCBeingCheckedForOrphanStatus) />
		</cfif>
	</cfloop>

	<cfreturn aOrphanList />
</cffunction>

<cffunction name="IsComponentParent" returntype="boolean" access="public" >
	<cfargument name="FamilyMap" type="struct" required="true" />
	<cfargument name="ComponentName" type="string" required="true" />

	<cfif structKeyExists(arguments.FamilyMap, arguments.ComponentName) EQ true >
		<cfreturn true />
	<cfelse>
		<cfreturn false />
	</cfif>
</cffunction>

<!--- FRONT END DRAW/RENDER FUNCTIONS --->

<cffunction name="RenderComponentMap" returntype="void" output="true" access="public" >
	<cfargument name="FamilyMap" type="struct" required="true" />
	<cfargument name="ListOfOrphans" type="array" required="true" />
	<cfargument name="ListOfPatriarchs" type="array" required="true" />
	<cfargument name="ComponentCollection" type="struct" required="true" />

	<cfset var sPatriarchName = "" />
	<cfset var sOrphanName = "" />

	<cfoutput>
		<div class="row" id="HeaderRow" >
			<h1>COMPONENT MAP</h1>
		</div>

		<!--- We only loop through the top level parents (Patriarchs) because by the end DrawFamily() will call itself again if it finds any children who are themselves parents --->
		<cfloop array="#arguments.ListOfPatriarchs#" index="sPatriarchName" >

			<cfset DrawFamily(
				FamilyMap = arguments.FamilyMap,
				ParentName = sPatriarchName,
				ParentInheritanceLevel = 0,
				ComponentCollection = arguments.ComponentCollection
			) />
		</cfloop>

		<div class="row">
			<div id="Orphans" class="col-24 ChildContainer" >
				<cfloop array="#arguments.ListOfOrphans#" index="sOrphanName" >

					<cfset DrawComponent(
						Type = "Child",
						Name = sOrphanName,
						Metadata = arguments.ComponentCollection[sOrphanName]
					) />

				</cfloop>
			</div>
		</div>
	</cfoutput>
</cffunction>

<cffunction name="DrawFamily" returntype="void" output="true" access="public" >
	<cfargument name="FamilyMap" type="struct" required="true" />
	<cfargument name="ParentName" type="string" required="true" />
	<cfargument name="ParentInheritanceLevel" type="numeric" required="true" />
	<cfargument name="ComponentCollection" type="struct" required="true" />

	<cfset var aChildrenWhoAreParents = arrayNew(1) />
	<cfset var sCurrentChild = "" />
	<cfset var sCurrentChildParent = "" />
	<cfset var aChildren = arguments.FamilyMap[arguments.ParentName] />
	<cfset var sParentContainerIndentation = "" />
	<cfset var sChildContainerColumnWidth = 18 />

	<cfif arguments.ParentInheritanceLevel GT 0 > <!--- The first row of child-parents of patriarchs will be on the same line. Subsequent child-parents will be indented --->
		<cfset sParentContainerIndentation = "Indent" & arguments.ParentInheritanceLevel />
		<cfset sChildContainerColumnWidth = sChildContainerColumnWidth - arguments.ParentInheritanceLevel />
	</cfif>

	<cfoutput>
		<div class="row" >
			<div class="col-1" ></div> <!--- Empty column to create a bit of breathing room (visually) between the border and the parent containers --->

			<div id="Parent-#LCase(arguments.ParentName)#" class="col-4 ParentContainer #sParentContainerIndentation# " >

				<cfset DrawComponent(
					Type = "Parent",
					Name = arguments.ParentName,
					Metadata = arguments.ComponentCollection[arguments.ParentName]
				) />

			</div>

			<div class="col-1" ></div> <!--- Empty column to create a bit of breathing room (visually) between the parents and the child containers --->

			<div id="Children-#LCase(arguments.ParentName)#" class="col-#sChildContainerColumnWidth# ChildContainer" >
				
				<cfloop array="#aChildren#" index="sCurrentChild" >
					
					<cfif IsComponentParent( FamilyMap=arguments.FamilyMap,ComponentName=sCurrentChild ) EQ true >
						<cfset arrayAppend(aChildrenWhoAreParents, sCurrentChild) />
					<cfelse>
						<cfset DrawComponent(
							Type = "Child",
							Name = sCurrentChild,
							Metadata = arguments.ComponentCollection[sCurrentChild]
						) />
					</cfif>

				</cfloop>

			</div>
		</div>

		<cfif arrayLen(aChildrenWhoAreParents) GT 0 >
			<cfloop array="#aChildrenWhoAreParents#" index="sCurrentChildParent" >

				<cfset DrawFamily(
					FamilyMap = arguments.FamilyMap,
					ParentName = sCurrentChildParent,
					ParentInheritanceLevel = arguments.ParentInheritanceLevel + 1,
					ComponentCollection = arguments.ComponentCollection
				) />

			</cfloop>
		</cfif>

	</cfoutput>
</cffunction>

<cffunction name="DrawComponent" returntype="void" output="true" access="public" >
	<cfargument name="Type" type="string" required="true" />
	<cfargument name="Name" type="string" required="true" />
	<cfargument name="Metadata" type="struct" required="true" />

	<cfset var aComponentFunctions = arrayNew(1) />
	<cfif structKeyExists(arguments.Metadata, "Functions") >
		<cfset aComponentFunctions = arguments.Metadata.Functions />
	</cfif>
	<cfset var stCurrentFunction = structNew() />

	<cfset var aComponentProperties = arrayNew(1) />
	<cfif structKeyExists(arguments.Metadata, "Properties") >
		<cfset aComponentProperties = arguments.Metadata.Properties />
	</cfif>
	<cfset var stCurrentProperty = structNew() />

	<cfoutput>
		<div id="#LCase(arguments.Name)#" class="Component #arguments.Type#" >
			<b>#Name#</b><br/>
			<hr/>
			
			<cfif arrayLen(aComponentProperties) GT 0 >
				<cfloop array="#aComponentProperties#" index="stCurrentProperty" >
					<span id="#Name#.#stCurrentProperty.Name#" title="#stCurrentProperty.Name#" ><u>#stCurrentProperty.Name#</u></span><br/>
				</cfloop>
			<cfelse>
				<i>No properties</i>
				<br/>
			</cfif>
			<br/>

			<cfif arrayLen(aComponentFunctions) GT 0 >
				<cfloop array="#aComponentFunctions#" index="stCurrentFunction" >
					<span class="CursorHover" id="#Name#.#stCurrentFunction.Name#" title="#stCurrentFunction.Name#" onclick="main.GetMethodData('#Name#', '#stCurrentFunction.Name#')" >#stCurrentFunction.Name#()</span><br/>
				</cfloop>
			<cfelse>
				<i>No methods</i>
			</cfif>
		</div>
	</cfoutput>
</cffunction>

<!--- INITIALIZATION --->

<cffunction name="init" returntype="void" access="public" output="true" >

	<cfset var stCurrentFailedComponent = structNew() />

	<cfset var sDirectory = "YOUR_CFC_PATH" />

	<cfset var stBuildComponentMetadataCollectionRet = BuildComponentMetadataCollection(
		ComponentDirectory=sDirectory,
		ComponentMapping="YOUR.CFC.MAPPING." <!--- REMEMBER THE TRAILING DOT! --->
	) />

	<cfset var stComponentCollection = stBuildComponentMetadataCollectionRet.stMetaData />
	<cfset var aListOfComponentsThatCouldNotBeCreated = stBuildComponentMetadataCollectionRet.aFailedInstantiations />

	<cfset var stFamilyMap = BuildFamilyMap(
		ComponentCollection=stComponentCollection
	) />

	<cfset var aListOfOrphans = BuildListOfOrphans(
		ComponentCollection=stComponentCollection,
		FamilyMap=stFamilyMap
	) />

	<cfset var aListOfPatriarchs = BuildListOfPatriarchs(
		FamilyMap=stFamilyMap
	) />

	<cfoutput>
		<!--- Here comes the HTML! --->
		<!DOCTYPE html>
		<html>
			<head>
				<title>Component Map</title>

				<meta name="viewport" content="width=device-width, initial-scale=1.0" />

				<link rel="stylesheet" type="text/css" href="Assets/main.css" />

				<link rel="stylesheet" type="text/css" href="Assets/jquery-ui/jquery-ui.min.css" />
				<link rel="stylesheet" type="text/css" href="Assets/jquery-ui/jquery-ui.structure.min.css" />
				<link rel="stylesheet" type="text/css" href="Assets/jquery-ui/jquery-ui.theme.min.css" />

				<script type="text/javascript" src="Assets/main.js" ></script>
				<script type="text/javascript" src="Assets/jquery.min.js" ></script>
				<script type="text/javascript" src="Assets/jquery-ui/jquery-ui.min.js" ></script>
				
				<script type="text/javascript">
					window.onload = function() {
						main.init();
					};

					#toScript(stFamilyMap, "main.oFamilyMap", false, true)#
				</script>
			</head>

			<body <!---onclick="getPos(event)"---> >
				<canvas id="DrawingBoard"></canvas>

				<cfset RenderComponentMap(
					FamilyMap = stFamilyMap,
					ListOfOrphans = aListOfOrphans,
					ListOfPatriarchs = aListOfPatriarchs,
					ComponentCollection = stComponentCollection
				) />
			
				<cfif arrayLen(aListOfComponentsThatCouldNotBeCreated) GT 0 >
					<div class="row" id="FailedInstantiationRow" >

						<h2>List of components that could not be instantiated:</h2>
						<table border="1" id="FailedInstantiationTable" >
							<thead>
								<th>Component</th>
								<th>Reason</th>
							</thead>
							<tbody>
								<cfloop array="#aListOfComponentsThatCouldNotBeCreated#" index="stCurrentFailedComponent" >
									<td>#stCurrentFailedComponent.Component#</td>
									<td>#stCurrentFailedComponent.Reason#</td>
								</cfloop>
							</tbody>
						</table>

					</div>
				</cfif>
			
			</body>
		</html>
	</cfoutput>
	
</cffunction>

<cfset init() />