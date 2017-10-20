function Create-HTMLReport {
	# https://powertoe.wordpress.com/2010/06/18/tackling-the-pipeline-with-advanced-functions/
	# Web Colors = https://en.wikipedia.org/wiki/Web_colors
	<#
	Get-Service | Create-HTMLReport -Title "TEST of Creation of HTML Table" -Post "Some Footer Information" -Highlight "Running"
	Get-Service | Create-HTMLReport -Title "TEST of Creation of HTML Table" -Post "Some Footer Information" -Highlight "True"
	Get-Service | Create-HTMLReport -Title "TEST of Creation of HTML Table" -Post "Some Footer Information" -Highlight "True" -HighlightColor "Red"
	Get-Service | Select-Object Name,CanPauseAndContinue,CanShutdown,CanStop,DisplayNAme,Status| Create-HTMLReport -Title "TEST of Creation of HTML Table" -Post "Some Footer Information" -Highlight "Running" -HighlightColor "Lime"
	(Create-Count).GetEnumerator() | select-object Name,Value | sort Value -Descending | Create-HTMLReport -Title "Programs Used - Frequency [TEST GROUP]" -Post "DRAFT - REMOVE COMMON ITEMS" -Highlight "22" -HighlightColor "Lime" -NoComputerName
	Get-EventLog -LogName application -EntryType Error,Warning -after (Get-Date).Adddays(-30) | Select EventID,EntryType,Message,Source,TimeGenerated  | Create-HTMLReport -Title "Application Logs - Last 30 days" -Post "" -Highlight "Error" -HighlightColor "Red"
	Get-EventLog -LogName System -EntryType Error,Warning -after (Get-Date).Adddays(-30) | Select EventID,EntryType,Message,Source,TimeGenerated  | Create-HTMLReport -Title "System Logs - Last 30 days" -Post "" -Highlight "Error" -HighlightColor "Red"
	#>
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$true,ValueFromPipeline=$True,Position = 0)]
	    [Object[]]$InputObject,
	    [string]$OutFile = "c:\temp\test.htm",
		[string]$Pre = "",
		[string]$Post = '',
		[string]$Title = "",
		[hashtable]$Colors = @{},
		[switch]$NoComputerName = $false,
		[string]$Search,
		[switch]$DoNotOpenFile,
        [switch]$SimpleMatch
	)

	begin {
	# REF: https://css-tricks.com/complete-guide-table-element/
$head = @"
<!-- disable ActiveX Prompting for local files -->
<!-- saved from url=(0014)about:internet -->
<!-- saved from url=(0016)http://localhost -->


<Title>TITLE_REPLACE</Title>
<style>
/*http://www.w3schools.com/css/*/

body { 
	background-color:#FFFFFF;
	/* font-family: Consolas,Courier,monospace !important; 
	font-family: "Segoe UI Light", "Segoe UI", Tahoma, Helvetica, sans-serif; */
	font-family: "Segoe UI","Lucida Grande",Verdana,Arial,Helvetica,sans-serif;
	font-size:10pt;
	color: #00368a;
}

td, th { 
	border:1px solid black; 
	border-collapse:collapse;
}

/*table {
	border-spacing: 0.5rem;
}*/

table {
	border-collapse: collapse;
}

th { 
	color:white;
	background-color:#01265f; 
}

table, tr, td, th { 
	padding: 
	2px; 
	margin: 0px; 
}

tr:nth-child(odd) {
	background-color: #eee
}

tr {
	color: gray;
}

td {
	color: Navy;
}

/* No Underline */
a {text-decoration: none}

/* unvisited link */
a:link {
    color: Navy;
}

/* visited link */
a:visited {
    color: Navy;
}

/* mouse over link */
a:hover {
    color: Green;
}

/* selected link */
a:active {
     color: Green;
}

/* td => column */
/*td:nth-child(3) {
	background: yellow; 
}*/

/* tr => row */
/*tr:nth-child(3) {
	background: yellow; 
}*/

/* Cell highlight on hover - th:hover also if you wish */
/*tr:hover { 
	background: yellow;
}*/

/* Cell highlight on style */
table.dataTable tbody tr.highlightRow {
   background-color: #ffaabb;
}


/* Full row highlight on hover */
tbody tr:hover {
	background: yellow;
}

table { 
	width:95%;
	margin-left:5px; 
	margin-bottom:20px;
}

Host {
    color: red;
}
</style>


<div id='debug'></div>
<H1>TITLE_REPLACE</H1>
"@

$JavaScript = @'

<script>
//DEBUG AREA
var allColGroup = document.getElementsByTagName("col");
var allColHeader = document.getElementsByTagName("th");
//document.getElementById("debug").innerHTML = 'COL Number: ' + allColGroup.length + '<BR>';
//document.getElementById("debug").innerHTML += 'Headers Number: ' + allColHeader.length + '<BR>';
for(var i = 0, max = allColHeader.length; i < max; i++) {
    var node = allColHeader[i];
	var ColGroupNode = allColGroup[i];
	if(node.childNodes[0]){
        var currentText = node.childNodes[0].nodeValue.trim();
        //document.getElementById("debug").innerHTML += currentText + '<BR>';
        node.setAttribute("class", currentText); //This "fills" the value of the class attribute w/ the test.
		ColGroupNode.setAttribute("class", currentText); //This "fills" the value of the class attribute w/ the test.
    }
}
//END DEBUG AREA

var allTableCells = document.getElementsByTagName("td");
// alert(allTableCells.length);

for(var i = 0, max = allTableCells.length; i < max; i++) {
    var node = allTableCells[i];
	
	if(node.childNodes[0]){

	    //get the text from the first child node - which should be a text node
	    var currentText = node.childNodes[0].nodeValue.trim(); 
		
		//Add Google Searchshould not have a link.
		//Array of words that don't get an hyperlink
        //TODO: Move to a POSH parameter.
		NoHrefArray = ['True','False','Running','Stopped','tcp'];
		if ( NoHrefArray.indexOf( currentText ) < 0 ){
			a = document.createElement('a');
			// a.href = 'https://www.google.com/?gws_rd=ssl#q=' + currentText;
			a.href = 'SEARCH_URL' + ' ' + currentText;
			a.target = '_blank';
			a.innerHTML = currentText;
			node.replaceChild(a,node.childNodes[0]);
		}
		
		//if (i<30){alert(i + "=>" + currentText);}

		//check for 'patterns' and assign this table cell's background color accordingly 
        //PATTERN_COLOR
	}
}
</script>
'@

    
    $PreContent = "<H2>$env:Computername</H2><BR>"

	if ($Pre) {
        $PreContent += $Pre
    }
    if ($NoComputerName) {$PreContent = $Pre}

    # Handle the color requirements per hash parameter.
    if ($Colors.Count -ne 0) {
	    foreach($Pattern in $Colors.Keys){
            $Color = $Colors[$Pattern]
            $ReplacementStringBGColor = "//PATTERN_COLOR `r"
            if ($Pattern -match "(.*)\*$"){
                # If we use "includes" instead of "startsWith" we can take care of cases where the pattern is anywhere within the string.
                $ReplacementStringBGColor += "`t`t if (currentText.trim().toUpperCase().startsWith('$($Matches[1])'.toUpperCase())){ `r"
            } else {
                $ReplacementStringBGColor += "`t`t if (currentText.trim().toUpperCase() == '$($Pattern)'.toUpperCase()){ `r"
            }
            $ReplacementStringBGColor += "`t`t`t node.style.backgroundColor = '$($Color)'; `r"
            $ReplacementStringBGColor += "`t`t }"
            $JavaScript = $JavaScript -replace '//PATTERN_COLOR', $ReplacementStringBGColor
        }
    }


	if ($Search -ne '') {
        # If we leave the value of $Search empty, the link will search for a local file.
		# $Search = 'https://www.google.com/?gws_rd=ssl#q=' + $Search
	} else {
		$Search = 'https://www.google.com/?gws_rd=ssl#q='
	}

	$JavaScript = $JavaScript -replace 'SEARCH_URL', $Search
	
    <#
    if (($Highlight -eq '') -and ($Search -eq $null)) {
		$JavaScript = ''
	}
    #>
	
	$PostContent = "$($JavaScript)<br>POSTCONTENT_REPLACE<br><I>Report run on $(Get-Date)</I>"
	$PostContent += "<br>Generated by Create-HTMLReport Function<br>Giuseppe J. Crisafulli. (c)2015-2017"
	$PostContent = ($PostContent -replace 'POSTCONTENT_REPLACE', $Post)
	# IF $title is empty, no <title>and no <H1> at the beginning of the page.
	$head = ($head -replace 'TITLE_REPLACE', $Title)
	$Body = ''
	$objects = @()
	}
	
	Process {
		$objects += $InputObject
	}
	
	end {
		$objects | Convertto-html -Head $head -Body $Body -PreContent $PreContent -PostContent $PostContent |
		Out-File $OutFile
		if ( -not $DoNotOpenFile ) { Invoke-Item $OutFile }
	}
}

# <colgroup><col/><col/><col/><col/><col/><col/><col/><col/></colgroup>
# http://niallodoherty.com/post.cfm/basic-html-to-excel-formatting
# http://codesnipers.com/?q=excel-compatible-html
