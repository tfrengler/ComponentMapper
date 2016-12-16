<cfprocessingdirective pageencoding="utf-8" />

<cfoutput>

<cfif structKeyExists(URL, "ComponentName") IS false AND structKeyExists(URL, "MethodName") IS false >
	ERROR:<br/>

	URL-key <b>ComponentName</b> or <b>MethodName</b> is missing...
	<cfabort />
<cfelse>
	<cfset sComponentName = toString(URL.ComponentName) />
	<cfset sMethodName = toString(URL.MethodName) />
</cfif>

<cftry>
	<cfset oComponentInstance = createObject("component", "YOUR_CFC_PATH.#sComponentName#") />
	<cfset stObjectMetaData = getMetaData(oComponentInstance) />
	<cfset aObjectMethods = stObjectMetaData.Functions />
	<cfset stMethodData = structNew() />

<cfcatch>
	<cfdump var="#cfcatch#" abort="true" />
</cfcatch>
</cftry>

<cfloop array="#aObjectMethods#" index="stCurrentMethod" >
	<cfif stCurrentMethod.Name EQ sMethodName >

		<cfset stMethodData = structCopy(stCurrentMethod) />
		<cfbreak />

	</cfif>
</cfloop>

<!--- The HTML output comes now --->

<style type="text/css">

###stMethodData.Name#_ArgumentsTable td, th {
	font-size: 10pt;
	border-color: black;
	border-width: 1pt;
	border-style: solid;
	padding-left: 0.3em;
	padding-right: 0.3em;
}

###stMethodData.Name#_ArgumentsTable th, .ui-dialog-titlebar {
	background-color: ##73AD21;
	color: white;
}

.ui-widget.ui-widget-content {
	border-width: 3pt;
	border-color: ##73AD21;
}

</style>

<section id="#stMethodData.Name#_Wrapper" >
	<div class="row" >

		<b>HINT:</b> 
		<cfif isDefined("stMethodData.Hint") IS true >
			#stMethodData.Hint#
		<cfelse>
			<i>No hint defined!</i>
		</cfif>

	</div>
	<br/>

	<div class="row" >

		<b>ARGUMENTS:</b>
		<br/>
		<cfif arrayLen(stMethodData.Parameters) IS 0 >
			<i>No arguments defined!</i>
		<cfelse>
		<table id="#stMethodData.Name#_ArgumentsTable" class="ArgumentsTable" >
			<thead>
				<th>Name</th>
				<th>Required</th>
				<th>Type</th>
				<th>Hint</th>
			</thead>
			<tbody>
				<cfloop array="#stMethodData.Parameters#" index="stCurrentParameter" >
					<tr>
						<td>
							<b>#stCurrentParameter.Name#</b>
						</td>
						<td>
							<cfif isDefined("stCurrentParameter.Required") IS true >
								#stCurrentParameter.Required#
							</cfif>
						</td>
						<td>
							<cfif isDefined("stCurrentParameter.Type") IS true >
								#stCurrentParameter.Type#
							</cfif>
						</td>
						<td>
							<cfif isDefined("stCurrentParameter.Hint") IS true >
								#stCurrentParameter.Hint#
							</cfif>
						</td>
					</tr>
				</cfloop>
			</tbody>
		</table>
		</cfif>
	</div>
	<br/>

	<div class="row" >

		<b>RETURN TYPE:</b> 
		<cfif isDefined("stMethodData.ReturnType") IS true >
			#stMethodData.ReturnType#
		<cfelse>
			<i>No return type defined!</i>
		</cfif>

	</div>
	<br/>

	<div class="row" >

		<b>ACCESS:</b> 
		<cfif isDefined("stMethodData.Access") IS true >
			#stMethodData.Access#
		<cfelse>
			<i>Access is not defined!</i>
		</cfif>
		
	</div>
</section>

</cfoutput>