xquery version "1.0-ml";
declare namespace tr = "http://BIPB.com/CITES";
declare namespace pp = "http://BIPB.com/CITES/purposes";
declare namespace sr = "http://BIPB.com/CITES/sources";
declare namespace info = "http://BIPB.com/CITES/taxa";
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module namespace fc="http://BIPB.com/CITES/facets" at "/facets.xqy";
import module namespace op="http://BIPB.com/CITES/options" at "/options.xqy";
import module namespace tools="http://BIPB.com/CITES/tools" at "/tools.xqy";

declare variable $q-text := 
	let $q := xdmp:get-request-field("q", "")
	return $q;
declare variable $agg := 
	let $agg := xdmp:get-request-field("agg")
	return $agg;

(:declare variable $results := search:search($q-text,$op:options, xs:unsignedLong(xdmp:get-request-field("start","1")));:)


declare variable $results :=
	let $options_s := 
		if ($q-text eq "")
		then (cts:index-order(cts:element-reference(xs:QName("tr:Taxon"),("type=string","collation=http://marklogic.com/collation//S1/AS/T00BB")),"ascending"))
		else (cts:score-order())
	let $options_f := 
		if ($q-text eq "")
		then  ("ascending","collation=http://marklogic.com/collation//S1/AS/T00BB")  
		else ("frequency-order","collation=http://marklogic.com/collation//S1/AS/T00BB")  
	
	
	let $query := 
		let $facet-queries := 
			for $f in fc:facets-all()
			return cts:element-value-query(xs:QName($f/@qname),$f/text(),())
		(:Here we build up an and queryt from a list of sub-querys.:)
		let $wordquery := if ($q-text) then cts:word-query($q-text) else ()
		let $unit := cts:element-value-query(xs:QName("tr:Unit"),"")
		return cts:and-query(($wordquery,$facet-queries,$unit))
	
	
	let $facets :=
		for $facet in ("Class","Order","Family")
    		let $qname := xs:QName(fn:string-join(("tr:",$facet)))
			let $values :=
				for $v in cts:element-values($qname, "", $options_f, $query)
				return <search:facet-value name="{$v}" count="{cts:frequency($v)}"> {$v} </search:facet-value>
			return
				<search:facet name="{$facet}">
					{$values}
				</search:facet>
  	(:Pagination:)
  	let $start := if (xdmp:get-request-field("start","1") = "") then 1 else xs:unsignedLong(xdmp:get-request-field("start","1"))
  	let $pagelength := 5
  	let $end := $start + $pagelength - 1
  	let $taxa := cts:element-values(xs:QName("tr:Taxon"),"",$options_f,$query)
  	let $taxa-page := $taxa[$start to $end]
  	let $taxa-query := cts:and-query(($query, cts:element-value-query(xs:QName("tr:Taxon"),$taxa-page)))
  	(:let $estimate := xdmp:estimate(cts:search(fn:collection("Trades"),$query,$options_s)) (:Count of trades.:):)
  	let $estimate := fn:count($taxa) (:Count of trades.:)

  	let $search-results :=
	    for $r in cts:search(fn:collection("Trades"),$taxa-query,$options_s)
	    	return <search:result uri="{$r/base-uri()}">{$r}</search:result>
	return 
	    <search:results start="{$start}" page-length="{$pagelength}" total="{$estimate}">
	    	<search:qtext>{$q-text}</search:qtext>
		    {$facets}
		    {$search-results}
	    </search:results>;


declare function local:pagination($results) {
	let $start := xs:unsignedLong($results/@start)
	let $length := xs:unsignedLong($results/@page-length)
	let $total := xs:unsignedLong($results/@total)
	let $last := xs:unsignedLong($start + $length - 1)
	let $end := if ($total > $last) then $last else $total
	let $qtext := $results/search:qtext[1]/text()
	let $next := if ($total > $last) then $last + 1 else ()
	let $previous := if (($start > 1) and ($start - $length > 0)) then fn:max((($start - $length),1)) else ()
	let $facet-strings :=
	  for $f in fc:facets-all()
	  return fn:string-join(('&amp;',$f/@name,'=',$f/text()))
	let $next-href := 
		if ($next)
		then fn:string-join((
			xs:string("/index.xqy?q="),
			xs:string(if ($qtext) then ($qtext) else ""),
			"&amp;start=",
			xs:string($next),
			"&amp;submitbtn=page",
			"&amp;agg=", 
			xs:string($agg),
			$facet-strings
			))
		else ()
	let $previous-href := 
		if ($previous)
		then fn:string-join((
			xs:string("/index.xqy?q="),
			xs:string(if ($qtext) then ($qtext) else ""),
			"&amp;start=",
			xs:string($previous),
			"&amp;submitbtn=page",
			"&amp;agg=",
			xs:string($agg),
			$facet-strings
			))
		else ()
	let $total-pages := fn:ceiling($total div $length)
	let $currpage := fn:ceiling($start div $length)
	let $pagemin := 
		fn:min(for $i in (1 to 4)
				where ($currpage - $i) > 0
				return $currpage - $i)
	let $rangestart := fn:max(($pagemin, 1))
	let $rangeend := fn:min(($total-pages,$rangestart + 4))

	return (
    	if($rangestart eq $rangeend)
    	then ()
    	else
    	<nav>
    		<ul class="pagination pagination-sm">
    			{if ($previous) 
    			then <li><a href="{$previous-href}" aria-label="Previous"><span aria-hidden="true">&laquo;</span></a></li> else ()}
    			{for $i in ($rangestart to $rangeend)
    				let $page-start := (($length * $i) + 1) - $length
    				let $page-href := fn:string-join((
    					"/index.xqy?q=",
    					xs:string(if ($qtext) then ($qtext) else ()),
    					"&amp;start=",
    					xs:string($page-start),
    					"&amp;submitbtn=page",
    					$facet-strings
    					))
    				return 
    					if ($i eq $currpage)
    					then <li class="active"><span >{$i}</span></li>
    					else <li><a href="{$page-href}">{$i}</a></li>
    			}
    			{ if ($next) 
    				then <li><a href="{$next-href}" aria-label="Next"><span aria-hidden="true">&raquo;</span></a></li> else ()}
    		</ul>
    	</nav>
   )
};





declare function local:tradeaggr($trades) {
	let $taxon := fn:distinct-values($trades//tr:Taxon)
	let $years := fn:distinct-values($trades//tr:Year)
	let $terms := fn:distinct-values(
		for $term in $trades//tr:Term
		order by fn:sum($trades[tr:Term eq $term]/tr:Quantity) descending
		return $term
		)
	let $show_other := if (fn:count($terms) >= 3)
						then fn:boolean("1")
						else fn:boolean(())
	let $terms_restricted := if ($show_other) then $terms[1 to 3] else $terms
	let $terms_other :=	if ($show_other) then $terms[4 to fn:count($terms)] else ()
	let $terms_tr :=
		for $term in $terms_restricted
			let $words := fn:tokenize($term, ' ')
			return <th style="text-align:center;text-transform:capitalize">{fn:string-join($words, ' ') }</th>
	let $details :=
		for $year in $years
			let $trades_other := $trades[tr:Year eq $year and tr:Term eq $terms_other]
			let $quantity_other := fn:sum($trades_other/tr:Quantity)
			let $quantities := 
				for $term in $terms_restricted
					let $quantity := fn:sum(tools:getquantity($trades[tr:Year eq $year and tr:Term eq $term]))
					return <td style="text-align:center">{$quantity}</td> 
			order by -$year
			return
				  <tr>
				  <td style="text-align:center">{$year}</td>
				  <td style="text-align:center">{fn:sum(tools:getquantity($trades[tr:Year eq $year]))}</td>
				  {$quantities}
				  {if ($show_other)
				  	then <td style="text-align:center">{$quantity_other}</td>
				  	else ()
				  }
				  </tr>
				    

	return <div>
		{tools:getinfohtml($trades)}
		<b>Imports into the UK:</b>
		<table style="width:100%" class= "table">
			<tr>
			    <th style="text-align:center">Year</th>
			    <th style="text-align:center">Total</th>
			    {$terms_tr}
			    {if ($show_other)
				  	then <th style="text-align:center">Other</th>
				  	else ()
				  }
			</tr>
			{$details}
			</table>
			<br></br>
		</div>

};	



declare function local:tradedetails($trades) {
	let $taxon := fn:distinct-values($trades//tr:Taxon)
	let $class := fn:distinct-values($trades//tr:Class)
	let $order := fn:distinct-values($trades//tr:Order)
	let $family := fn:distinct-values($trades//tr:Family)
	(:Loop through taxa:)
	let $taxa-trades :=
		let $details := 
			for $trade in $trades
			let $year := $trade/tr:Year
			let $from := $trade/tr:Exporter
			let $purpose := tools:getpurpose($trade)
			let $source := tools:getsource($trade)
			let $quantity := tools:getquantity($trade)
			order by -$year
			return
				  <tr>
				    <td style="text-align:center">{$year}</td>
				    <td style="text-align:center">{$quantity}</td> 
				    <td>{tools:getcountry($from)}</td>
				    <td>{$source}</td>
				    <td>{$purpose}</td>
				  </tr>
		return <div>
			{tools:getinfohtml($trades)}
			<b>Imports into the UK:</b>
			<table style="width:100%" class= "table">
				<tr>
				    <th style="text-align:center">Year</th>
				    <th style="text-align:center">Quantity</th> 
				    <th>Exporter</th>
				    <th>Source</th>
				    <th>Purpose</th>
				</tr>
				{$details}
				</table>
				<br></br>
			</div>
	return $taxa-trades			
};

declare function local:search-results() {
	let $docs :=
		for $result in $results//search:result
		let $uri := fn:data($result/@uri)
		let $doc := fn:doc($uri)
		return $doc
	let $taxa := fn:distinct-values($docs//tr:Taxon)
	let $items :=
		for $taxon in $taxa
		 	let $trades := $docs//tr:trade[tr:Taxon eq $taxon]
			return
			if ($agg eq "on") then
				<div>{local:tradeaggr($trades)}</div>
				
			else
				<div>{local:tradedetails($trades)}</div>
	return 
		if ($items)
		then 
			<div>
				<div>{local:pagination($results)}</div>
				<div class="row">
					<div class="col-md-9">
						<p>Search took: {fn:substring(xs:string(xdmp:elapsed-time()),3,3)}s</p>
						{($items)}
					</div>
				</div>
			</div>
	else <div><p>Sorry, no results for your search.</p></div>
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
				<div class="col-md-3">
					{fc:facets($results)}
				</div>
				<div class="col-md-9">
					<div class="row">
						<div class="col-md-9">
							<form name="form1" method="get" action="index.xqy" id="form1">
								<div class="input-group">
									<span class="input-group-addon" id="basic-addon1">Search</span>
									<input type="text" class="form-control" placeholder="Taxon, Genus, Family etc." aria-describedby="basic-addon1" name="q" id="q" value="{$q-text}"></input>
									<span class="input-group-btn">
									<button class="btn btn-default" type="submit">Go!</button>
		 							</span>
								</div>
								
								{if ($agg = "on") then
									<div class="checkbox">
									<label><input type="checkbox" name="agg" id="agg" checked="on">Aggregate Results by Year</input></label>
									</div>
								else
									<div class="checkbox">
									<label><input type="checkbox" name="agg" id="agg">Aggregate Results by Year</input></label>
									</div>
								}
								
							</form>
						</div>
					</div>
					{local:search-results()}
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