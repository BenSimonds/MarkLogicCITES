xquery version "1.0-ml";
declare namespace tr = "http://BIPB.com/CITES";
declare namespace pp = "http://BIPB.com/CITES/purposes";
declare namespace sr = "http://BIPB.com/CITES/sources";
declare namespace info = "http://BIPB.com/CITES/taxa";
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module namespace json="http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";
import module namespace fc="http://BIPB.com/CITES/facets" at "/facets.xqy";
import module namespace op="http://BIPB.com/CITES/options" at "/options.xqy";
import module namespace tools="http://BIPB.com/CITES/tools" at "/tools.xqy";

(:Aim, use some search criteria to generate table of trends in trades:)

declare variable $q-text := 
	let $q := xdmp:get-request-field("q","Panthera leo")
	return $q;
declare variable $agg := 
	let $agg := xdmp:get-request-field("agg")
	return $agg;


declare function local:refineresults() {
	let $wordquery	:= if ($q-text eq "") then () else cts:word-query($q-text)
	let $cname 		:= if (xdmp:get-request-field("common_name","Any") 	eq "Any") then () else cts:element-value-query(xs:QName("tr:Common_Name"),xdmp:get-request-field("common_name",()))
	let $class 		:= if (xdmp:get-request-field("class","Any")		eq "Any") then () else cts:element-value-query(xs:QName("tr:Class"),xdmp:get-request-field("class",()))
	let $order 		:= if (xdmp:get-request-field("order","Any")		eq "Any") then () else cts:element-value-query(xs:QName("tr:Order"),xdmp:get-request-field("order",()))
	let $family 	:= if (xdmp:get-request-field("family","Any") 		eq "Any") then () else cts:element-value-query(xs:QName("tr:Fammily"),xdmp:get-request-field("family",()))
	let $exporter 	:= if (xdmp:get-request-field("exporter","Any")		eq "Any") then () else cts:element-value-query(xs:QName("tr:Exporter"),xdmp:get-request-field("exporter",()))
	let $purpose 	:= if (xdmp:get-request-field("purpose","Any")		eq "Any") then () else cts:element-value-query(xs:QName("tr:Purpose"),xdmp:get-request-field("purpose",()))
	let $source 	:= if (xdmp:get-request-field("source","Any")		eq "Any") then () else cts:element-value-query(xs:QName("tr:Source"),xdmp:get-request-field("source",()))
	let $term 		:= if (xdmp:get-request-field("term","Any")			eq "Any") then () else cts:element-value-query(xs:QName("tr:Term"),xdmp:get-request-field("term",()))
	let $yearstart 	:= if (xdmp:get-request-field("yearstart","Any")	eq "Any") then () else cts:element-range-query(xs:QName("tr:Year"),">=", xs:int(xdmp:get-request-field("yearstart","2000")))
	let $yearend 		:= if (xdmp:get-request-field("yearend","Any")		eq "Any") then () else cts:element-range-query(xs:QName("tr:Year"),"<=", xs:int(xdmp:get-request-field("yearend","3000")))

	let $unit := cts:element-value-query(xs:QName("tr:Unit"),"")

	let $querylist := 
		($wordquery,
		$cname,
		$class,
		$order,
		$family,
		$exporter,
		$yearstart,
		$yearend,
		$source,
		$purpose,
		$term,
		$unit
		)
			
	let $results := 
		if (fn:count($querylist) eq 0)
		then fn:collection("Trades")
		else cts:search(fn:collection("Trades"),cts:and-query($querylist))
	let $trades-return := $results/tr:trade
	return $trades-return
};



declare variable $xvar := xdmp:get-request-field("xvar","Purpose");
declare variable $yvar := xdmp:get-request-field("yvar","Trades");
declare variable $orderby := xdmp:get-request-field("orderby","y");

declare variable $refinedtrades := local:refineresults();

declare function local:simplejson() {
	let $trades := local:refineresults()
	let $bars := fn:distinct-values($trades/*[name() eq $xvar])
	let $a := 
		for $bar in $bars
		let $bartrades := $trades/*[name() eq $xvar and text() eq $bar]/..
		let $q := fn:sum(tools:getquantity($bartrades)) 
		let $q-nice := fn:format-number($q,'#,##0')
		let $n := fn:count($bartrades)
		let $bartext :=
			if ($xvar eq "Source") then tools:getsource_code($bar)
			else if ($xvar eq "Purpose") then tools:getpurpose_code($bar)
			else if ($xvar eq "Exporter") then tools:getcountry($bar)
			else $bar
		let $ob := 
			if ($orderby eq "x") then $bar
			else if ($orderby eq "y") then
				if ($yvar eq "Trades") then -$n
				else -$q
			else ()  
		order by $ob
		return fn:string-join((
			"{&#34;XVar&#34;:&#34;",
			xs:string($bartext),
			"&#34;,&#34;Quantity&#34;:",
			xs:string($q),
			",&#34;Trades&#34;:",
			xs:string($n),"}"
		))
	let $b := 	fn:string-join($a,',')
	return fn:string-join(("{&#34;trades&#34;:[",$b,"]}"))
		
		
};


declare function local:simpletable() {
	let $trades := local:refineresults()
	let $years := fn:distinct-values($trades/tr:Year)
	let $a := 
		for $year in $years	
		let $q := fn:sum(tools:getquantity($trades[tr:Year eq $year]))
		let $q-nice := fn:format-number($q,'#,##0')
		let $n := fn:count($trades[tr:Year eq $year])
		let $n-nice := fn:format-number($n,'#,##0')
		order by $year
		return 
		<tr>
			<td style="text-align:center">{$year}</td>
			<td style="text-align:center">{$q-nice}</td>
			<td style="text-align:center">{$n-nice}</td>
		</tr>
	return 
		<table class="table" style="width:100%">
			<tr>
				<th style="text-align:center">Year</th>
				<th style="text-align:center">Quantity</th>
				<th style="text-align:center">Trades</th>
			</tr>
			{$a}
		</table>
};




declare function local:formfield($name, $field, $options, $any) {
	let $formline := 
	<div>
		<label for="startyear" class="control-label">{$name}</label>
		<select class="form-control"  name= "{$field}" id="{$field}">
			{if ($any) then <option>Any</option> else ()}
			{for $option in $options
			order by $option
			return
			if (xdmp:get-request-field($field) eq $option) 
			then <option value="{$option}" selected="selected">{if ($option ne '') then $option else "Unknown"}</option>
			else <option value="{$option}" >{if ($option ne '') then $option else "Unknown"}</option>
			}
			</select>
		</div>
	return $formline	
};

declare function local:refineform() {
	let $form :=
		<div>

		<form name="form2" method="get" action="{fn:string-join(("trends.xqy?q=",xdmp:get-request-field("q")))}" id="form2">
			<h3>Search</h3>
			<div class="form-group">
				<div class="input-group">
					<span class="input-group-addon" id="basic-addon1">Search</span>
					<input type="text" class="form-control" placeholder="Taxon, Genus, Family etc." aria-describedby="basic-addon1" name="q" id="q" value="{$q-text}"></input>
				</div>
			</div>		
			<h3>Refine</h3>
			<div class="form-group">
				{local:formfield("Start Year", "yearstart", fn:distinct-values($refinedtrades/tr:Year),fn:true())}
				{local:formfield("End Year", "yearend",fn:distinct-values($refinedtrades/tr:Year),fn:true())}
				<div>
					<label for="startyear" class="control-label">Exporter</label>
					<select class="form-control"  name= "exporter" id="exporter">
						<option>Any</option>
				{for $option in fn:distinct-values($refinedtrades/tr:Exporter)
					order by $option
					return
					if (xdmp:get-request-field("exporter") eq $option) 
					then <option value="{$option}" selected="selected">{tools:getcountry($option)}</option>
					else <option value="{$option}">{tools:getcountry($option)}</option>
				}
					</select>
				</div>
				<div>
					<label for="startyear" class="control-label">Source</label>
					<select class="form-control"  name= "source" id="source">
						<option>Any</option>
				{for $option in fn:distinct-values($refinedtrades/tr:Source)
					order by $option
					return
					if (xdmp:get-request-field("source") eq $option) 
					then <option value="{$option}" selected="selected">{tools:getsource_code($option)}</option>
					else <option value="{$option}">{tools:getsource_code($option)}</option>
				}
					</select>
				</div>
				<div>
					<label for="purpose" class="control-label">Purpose</label>
					<select class="form-control"  name= "purpose" id="purpose">
						<option>Any</option>
				{for $option in fn:distinct-values($refinedtrades/tr:Purpose)
					order by $option
					return
					if (xdmp:get-request-field("purpose") eq $option) 
					then <option value="{$option}" selected="selected">{tools:getpurpose_code($option)}</option>
					else <option value="{$option}">{tools:getpurpose_code($option)}</option>
				}
					</select>
				</div>
				{local:formfield("Class", "class",fn:distinct-values($refinedtrades/tr:Class),fn:true())}
				{local:formfield("Order", "order",fn:distinct-values($refinedtrades/tr:Order),fn:true())}
				{local:formfield("Family", "family",fn:distinct-values($refinedtrades/tr:Family),fn:true())}
				{local:formfield("Common Name", "common_name",fn:distinct-values($refinedtrades/tr:Common_Name),fn:true())}
				<br/>
				<h3>Plot</h3>
				{local:formfield("X Variable", "xvar",("Year","Purpose","Source","Common_Name","Family","Order","Class","Exporter"),fn:false())}
				{local:formfield("Y Variable", "yvar",("Quantity","Trades"),fn:false())}
				
				<label for="order by" class="control-label">Order By</label>
				<select class="form-control"  name= "orderby" id="orderby">
				{if (xdmp:get-request-field("orderby") eq "x") 
					then <div><option value="x" selected="selected">Category</option><option value="y">Value</option></div>
					else <div><option value="x">Category</option><option value="y" selected="selected">Value</option></div>
				}
				</select>

				<input class="btn btn-default" type="submit" value="Refine"></input>
			</div>
		</form>
		</div>
	return $form
};


xdmp:set-response-content-type("text/html; charset=utf-8"),
'<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',
<html xmlns="http://www.w3.org/1999/xhtml" lang="en">
<head>
	<meta charset="utf-8"></meta>
	<meta http-equiv="X-UA-Compatible" content="IE=edge"></meta>
	<meta name="viewport" content="width=device-width, initial-scale=1"></meta>
	<!-- The above 3 meta tags *must* come first in the head; any other head content must come *after* these tags -->
	<meta name="description" content="Test App with MarkLogic"></meta>
	<meta name="author" content="Ben Simonds"></meta>
	<link rel="icon" href="../../favicon.ico"></link>

	<title>CITES Trades</title>

	<!-- Bootstrap core CSS -->
	<link href="node_modules/bootstrap/dist/css/bootstrap.min.css" rel="stylesheet"></link>

	<!-- Custom styles for this template -->
	<link href="css/main.css" rel="stylesheet"></link>

</head>

<body>

	<nav class="navbar navbar-inverse navbar-fixed-top">
		<div class="container">
			<div class="navbar-header">
				<button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#navbar" aria-expanded="false" aria-controls="navbar">
					<span class="sr-only">Toggle navigation</span>
					<span class="icon-bar"></span>
					<span class="icon-bar"></span>
					<span class="icon-bar"></span>
				</button>
				<a class="navbar-brand" href="#">
				    <img class="brandimg" alt="Brand" src="img/citeslogotiny.png"></img>
				</a>
				<a class="navbar-brand" href="/index.xqy">Imports into Great Britain</a>
			</div>
			<div id="navbar" class="collapse navbar-collapse">
				<ul class="nav navbar-nav">
					<li><a href="/index.xqy">Search</a></li>
					<li class="active"><a href="/trends.xqy">Trends</a></li>
					<li><a href="https://github.com/BenSimonds/MarkLogicDemoApp">Docs</a></li>
				</ul>
			</div><!--/.nav-collapse -->
		</div>
	</nav>

	<div class="container">

		<div class="main">
			<div class="row">
				<div class="col-md-12">
					<h3>Search for a speices, and refine your results below.</h3>
				</div>
			</div>	
			<div class="row">
				<div class="col-md-3">
					{local:refineform()}
				</div>
				<div class="col-md-9">
					<div class="row">
						<div class="col-md-9">
							<h3>{$yvar} by {$xvar}</h3>
							Note: You must limit your search in some way, too much data otherwise for now... 
							<svg class="chart"></svg>
							<h3>Data</h3>
							{local:simpletable()}
							<h3>JSON</h3>
							<pre>{local:simplejson()}</pre>
							<h3>Raw</h3>
							<pre>{local:refineresults()}</pre>
						</div>
					</div>
				</div>
			</div> <!--End of row-->	
		</div>
	</div><!-- /.container -->


    <!-- Bootstrap core JavaScript
    ================================================== -->
    <!-- Placed at the end of the document so the pages load faster -->
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js"></script>
    <script src="node_modules/bootstrap/dist/js/bootstrap.min.js"></script>
    <!-- Lets add some d3 sweetness -->
    <script src="node_modules/d3/d3.min.js"  charset="utf-8"></script>
    <script>
    	var tradedata = {local:simplejson()}
    	console.log("helloworld")
    	

    	var data = tradedata.trades;
    	


    	console.log(data)

    	var height = 500,
    	    barWidth = 40;
        
        var lpad = 50;
        var rpad = 25;
    	var tpad = 25;
    	var bpad = 100;

    	var fquantity = d3.format(",.2f")
    	<!--
    	var fquantity_scale = function(n) {
    		var out = "";
    		if (n >  1000000) {
    				out = fquantity(n/1000000) + "M";
    		} else if (n >  1000) {
    				out = fquantity(n/1000) + "k";
    		} else {
    			    out = fquantity(n);
    		}
    		return out;
    	};
    	-->

    	var y = d3.scale.linear()
    	    .domain([0, d3.max(data, function(d) {{return d.{$yvar}; }})])
    	    .range([0, height - (tpad + bpad)]);

    	console.log(y)    

    	var chart = d3.select(".chart")
    	    .attr("width", barWidth * data.length + lpad + rpad)
    	    .attr("height", height);

    	var bar = chart.selectAll("g")
    	    .data(data)
    	  .enter().append("g")
    	    .attr("transform", function(d, i) {{ return "translate(" + (i * barWidth + lpad) + ",0)"; }});

    	bar.append("rect")
    	    .attr("width", barWidth - 1)
    	    .attr("height", function(d) {{ return y(d.{$yvar}); }})
    	    .attr("y", function(d) {{ return height - y(d.{$yvar}) - bpad; }});

    	bar.append("text")
    	    .attr("y", function(d) {{ return height - y(d.{$yvar}) - bpad - 5; }})
    	    .attr("x", barWidth / 2)
    	    .attr("text-anchor", "middle")
    	    .text(function(d) {{ return fquantity_scale(d.{$yvar}); }});

    	bar.append("text")
    	    .attr("y", height - bpad + 10)
    	    .attr("x", barWidth / 2)
    	    .style("text-anchor", "end")
    	    .style("fill", "black")
    	    .attr("transform", function(d, i) {{ return "rotate(-45," + String(0.5 * barWidth) + ", " + String(height - bpad + 10) + ")"; }})
    	    <!--
    	    .text(function(d,i) { 
    	    	if (d.XVar.length > 20){
					return d.XVar.substring(0,20) + "\r\n...";
    	    	} else {
					return d.XVar;
    	    	}
    	    	});
    	  
    	    -->


    </script>
</body>
</html>