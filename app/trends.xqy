xquery version "1.0-ml";
declare namespace tr = "http://BIPB.com/CITES";
declare namespace pp = "http://BIPB.com/CITES/purposes";
declare namespace sr = "http://BIPB.com/CITES/sources";
declare namespace info = "http://BIPB.com/CITES/taxa";
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module namespace fc="http://BIPB.com/CITES/facets" at "/facets.xqy";
import module namespace op="http://BIPB.com/CITES/options" at "/options.xqy";
import module namespace tools="http://BIPB.com/CITES/tools" at "/tools.xqy";

(:Aim, use some search criteria to generate table of trends in trades:)

declare variable $q-text := 
	let $q := xdmp:get-request-field("q")
	return $q;
declare variable $agg := 
	let $agg := xdmp:get-request-field("agg")
	return $agg;

declare variable $results := cts:search(fn:collection("Trades"),$q-text);

declare variable $alltrades := if ($q-text ne '') then $results//tr:trade else fn:collection("Trades")//tr:trade;

declare function local:simpletest() {
	let $trades := local:refineresults($alltrades)
	let $years := fn:distinct-values($trades/tr:Year)
	let $a := 
		for $year in $years	
		let $q := fn:sum($trades[tr:Year eq $year]/tr:Quantity)
		let $q-nice := fn:format-number($q,'#,##0')
		order by $year
		return <p> {$year}:{$q} </p>
	return $a
};

declare function local:refineresults($alltrades) {
	let $class := xdmp:get-request-field("class",())
	let $order := xdmp:get-request-field("order")
	let $family := xdmp:get-request-field("family")
	let $yearstart := xdmp:get-request-field("startyear")
	let $yearend := xdmp:get-request-field("endyear")
	let $trades-return := 
	for $trade in $alltrades
		let $c := if ($class eq "Any") then xs:boolean(1) else if ($class) then ($trade/tr:Class = $class) else xs:boolean(1)
		let $o := if ($order eq "Any") then xs:boolean(1) else if ($order) then ($trade/tr:Order = $order) else xs:boolean(1) 
		let $f := if ($family eq "Any") then xs:boolean(1) else if ($family) then ($trade/tr:Family = $family) else xs:boolean(1) 
		let $y1 := if ($yearstart eq "Any")then xs:boolean(1) else if ($yearstart) then ($trade/tr:Year >= xs:int($yearstart)) else xs:boolean(1) 
		let $y2 := if ($yearend eq "Any")then xs:boolean(1) else if ($yearend) then ($trade/tr:Year <= xs:int($yearend)) else xs:boolean(1)
		where 
		($c and $o and $f and $y1 and $y2)
		return $trade
	return $trades-return
};

declare function local:results-trades() {
	let $alltrades :=  
    for $result in $results//search:result
		  let $uri := $result/@uri
		  let $doc := fn:doc($uri)
      let $trades := $doc//tr:trade
		  return $trades
	return $alltrades
};


declare function local:formfield($name, $field, $options) {
	let $formline := 
	<div>
		<label for="startyear" class="control-label">{$name}</label>
		<select class="form-control"  name= "{$field}" id="{$field}">
			<option>Any</option>
			{for $option in $options
			order by $option
			return
			if (xdmp:get-request-field($field) eq $option) 
			then <option selected="selected">{$option}</option>
			else <option>{$option}</option>
			}
			</select>
		</div>
	return $formline	
};

declare function local:refineform() {
	let $form :=
		<div>
		<form name="form2" method="get" action="{fn:string-join(("trends.xqy?q=",xdmp:get-request-field("q")))}" id="form2">
			<div class="form-group">
				{local:formfield("Start Year", "yearstart", fn:distinct-values($alltrades//tr:Year))}
				{local:formfield("End Year", "yearend",fn:distinct-values($alltrades//tr:Year))}
				{local:formfield("Class", "class",fn:distinct-values($alltrades//tr:Class))}
				{local:formfield("Order", "order",fn:distinct-values($alltrades//tr:Order))}
				{local:formfield("Family", "family",fn:distinct-values($alltrades//tr:Family))}
				{local:formfield("Common Name", "common_name",fn:distinct-values($alltrades//tr:Common_Name))}
				<br/>
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
				<a class="navbar-brand" href="/index.xqy">CITES Imports into Great Britain</a>
			</div>
			<div id="navbar" class="collapse navbar-collapse">
				<ul class="nav navbar-nav">
					<li class="active"><a href="/index.xqy">Search</a></li>
					<li><a href="/trends.xqy">Trends</a></li>
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
					<form name="form1" method="get" action="trends.xqy" id="form1">
						<div class="input-group">
							<span class="input-group-addon" id="basic-addon1">Search</span>
								<input type="text" class="form-control" placeholder="Taxon, Genus, Family etc." aria-describedby="basic-addon1" name="q" id="q" value="{$q-text}"></input>
								<span class="input-group-btn">
								<button class="btn btn-default" type="submit">Go!</button>
		 					</span>
						</div>
					</form>
				</div>
			</div>	
			<div class="row">
				<div class="col-md-3">
					<h3>Refine</h3>
					{local:refineform()}
				</div>
				<div class="col-md-9">
					<div class="row">
						<div class="col-md-9">
							{local:simpletest()}
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
    <script src="../../dist/js/bootstrap.min.js"></script>
    <!-- IE10 viewport hack for Surface/desktop Windows 8 bug -->
    <script src="../../assets/js/ie10-viewport-bug-workaround.js"></script>
</body>
</html>