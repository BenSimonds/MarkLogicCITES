xquery version "1.0-ml";
declare namespace tr = "http://BIPB.com/CITES";
declare namespace pp = "http://BIPB.com/CITES/purposes";
declare namespace sr = "http://BIPB.com/CITES/sources";
declare namespace info = "http://BIPB.com/CITES/taxa";
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";

declare variable $options := 
  <options xmlns="http://marklogic.com/appservices/search">
  <constraint name="year">
  	<range type="xs:int">
  		<element ns="http://BIPB.com/CITES" name="Year"/>
  		<facet-option>limit=30</facet-option>
  		<facet-option>descending</facet-option>
  	</range>
  </constraint>
  <constraint name="common_name">
  	<value type="xs:string" collation="http://marklogic.com/collation//S1/T00BB/AS">
  		<element ns="http://BIPB.com/CITES" name="Common_Name"/>
  	</value>
  </constraint>
  <constraint name="class">
  	<range type="xs:string" collation="http://marklogic.com/collation//S1/T00BB/AS">
  		<element ns="http://BIPB.com/CITES" name="Class"/>
  		<facet-option>limit=30</facet-option>
  		<facet-option>descending</facet-option>
  	</range>
  </constraint>
  <constraint name="order">
  	<range type="xs:string" collation="http://marklogic.com/collation//S1/T00BB/AS">
  		<element ns="http://BIPB.com/CITES" name="Order"/>
  		<facet-option>limit=30</facet-option>
  		<facet-option>frequency-order</facet-option>
  		<facet-option>descending</facet-option>
  	</range>
  </constraint> 
  <constraint name="family">
  	<range type="xs:string" collation="http://marklogic.com/collation//S1/T00BB/AS">
  		<element ns="http://BIPB.com/CITES" name="Family"/>
  		<facet-option>limit=30</facet-option>
  		<facet-option>frequency-order</facet-option>
  		<facet-option>descending</facet-option>
  	</range>
  </constraint> 
  	<term>
  	    <term-option>case-insensitive</term-option>
  	    <term-option>stemmed</term-option>
  	</term>
  	<searchable-expression>
  	    fn:collection("Trades")
  	</searchable-expression>
  	<search:operator name="sort">
  	  <search:state name="alphabetical">
  	    <search:sort-order direction="ascending" type="xs:string" collation="http://marklogic.com/collation//S1/T00BB/AS">
  	      <search:element ns="http://BIPB.com/CITES" name="Taxon"/>
  	    </search:sort-order>
  		<search:sort-order>
  			<search:score/>
  		</search:sort-order>
  	</search:state>
  	</search:operator>
  </options>;

declare variable $q-text := 
	let $q := xdmp:get-request-field("q", "sort:alphabetical")
	return $q;
declare variable $agg := 
	let $agg := xdmp:get-request-field("agg")
	return $agg;
	

declare variable $results := search:search($q-text,$options, xs:unsignedLong(xdmp:get-request-field("start","1")));

declare function local:pagination($resultspage) {
	let $start := xs:unsignedLong($resultspage/@start)
	let $length := xs:unsignedLong($resultspage/@page-length)
	let $total := xs:unsignedLong($resultspage/@total)
	let $last := xs:unsignedLong($start + $length - 1)
	let $end := if ($total > $last) then $last else $total
	let $qtext := $resultspage/search:qtext[1]/text()
	let $next := if ($total > $last) then $last + 1 else ()
	let $previous := if (($start > 1) and ($start - $length > 0)) then fn:max((($start - $length),1)) else ()
	let $next-href := 
		if ($next)
		then fn:concat("/index.xqy?q=",if ($qtext) then ($qtext) else (),"&amp;start=",$next,"&amp;submitbtn=page","&amp;agg=", $agg)
		else ()
	let $previous-href := 
		if ($previous)
		then fn:concat("/index.xqy?q=",if ($qtext) then ($qtext) else (),"&amp;start=",$previous,"&amp;submitbtn=page","&amp;agg=", $agg)
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
    				let $page-href := concat("/index.xqy?q=",if ($qtext) then ($qtext) else (),"&amp;start=",$page-start,"&amp;submitbtn=page")
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

declare function local:getfacetlink($facet as xs:string, $value as xs:string, $include as xs:boolean) as xs:string{
	let $search-terms := fn:tokenize($q-text, '\+') (:break up search terms into units:)
	let $search-facet := fn:string-join(($facet, ':' , $value))
	let $terms_keep :=
		for $term in $search-terms
		where (fn:not(fn:contains($term, $facet)))
		return $term
	let $terms_keep := fn:string-join($terms_keep, '+')
	let $link :=
		if ($include)
		then fn:string-join(('http://localhost:8050/index.xqy?q=', $terms_keep, ' ' , $search-facet, '&amp;agg=',$agg))
		else fn:string-join(('http://localhost:8050/index.xqy?q=', $search-facet, '&amp;agg=',$agg))
  	return $link
};


declare function local:facets()
{
  for $facet in $results//search:facet
  	let $facet-name := $facet/@name/string()
  	let $facet-values :=
  		for $facet-value in $facet/search:facet-value
  			let $value-name := 
  				if ($facet-value/@name ne '')
  				then xs:string($facet-value/@name/string())
  				else "Unknown"
  			let $value-count := $facet-value/@count
  			let $value-text :=
  				if ($value-count >= 1000)
  				then fn:string-join((xs:string(fn:floor($value-count div 1000)) , "k+"))
  				else $value-count/string()
  			return <li> <a href="{local:getfacetlink($facet-name,$facet-value,xs:boolean(1))}">{$facet-value}</a>&nbsp;<small>[{$value-text}]</small></li> 
  	return
  		<div class="facet">
  			<h3>{$facet-name}</h3>
  			<ul>{$facet-values}</ul>
  		</div>
};
		

declare function local:getquantity($trades) as xs:float {
	let $max := for $trade in $trades/descendant-or-self::tr:trade
		let $importer := xs:float($trade/tr:Importer_reported_quantity/text())
  		let $exporter := xs:float($trade/tr:Exporter_reported_quantity/text())
  		let $max := fn:max(($importer, $exporter))
  		return $max
	return fn:round(fn:sum($max))
  	};

declare function local:getpurpose($trade) {
	let $code := $trade/tr:Purpose
	let $purpose := fn:doc("purposes.xml")/pp:purposes/pp:purpose[@id eq $code]/text()
	return 
	if ($purpose) then
		$purpose
	else
		"Unknown"
};

declare function local:getsource($trade) {
	let $code := $trade/tr:Source
	let $source := fn:doc("sources.xml")/sr:sources/sr:source[@id eq $code]/text()
	return 
	if ($source) then
		$source
	else
		"Unknown"
};

declare function local:getinfo($taxon) {
	let $info_uri := fn:string-join(("taxa/",$taxon,".xml"))
	let $info := fn:doc($info_uri)
	let $c_name := $info//info:common_name/text()
	return $info
};

declare function local:getimage($taxon) {
	let $uri := local:getinfo($taxon)//info:img_uri/text()
	return 
	if (fn:doc($uri))
	then <div class="pull-right"><img class="img-rounded img-species" alt="{$taxon}" src="get-file.xqy?uri={$uri}"/></div>
	else ()
};

declare function local:getinfohtml($doc) {
	let $taxon := fn:distinct-values($doc//tr:Taxon)
	let $class := fn:distinct-values($doc//tr:Class)
	let $order := fn:distinct-values($doc//tr:Order)
	let $family := fn:distinct-values($doc//tr:Family)
	let $common_name := local:getinfo($taxon)//info:common_name
	let $wikilink := local:getinfo($taxon)//info:wikilink
	let $conservation_status := local:getinfo($taxon)//info:conservation_status
	let $c-quoted := fn:string-join(("&#34;",$common_name,"&#34;"))
	let $t-quoted := fn:string-join(("&#34;",$taxon,"&#34;"))
	return
	<div>
		{if ($common_name eq $taxon) 
			then <h4>{$taxon}<a href="{local:getfacetlink('taxon',$t-quoted,xs:boolean(0))}">&nbsp;&#x1F517;</a></h4>
		else if ($common_name ne '')
			then <h4>{$common_name} ({$taxon})<a href="{local:getfacetlink('common_name',$c-quoted,xs:boolean(0))}">&nbsp;&#x1F517;</a></h4>
		else <h4>{$taxon}<a href="{local:getfacetlink('taxon',$t-quoted,xs:boolean(0))}">&nbsp;&#x1F517;</a></h4>}
		{local:getimage($taxon)}
		<p>
		{if ($class) 
			then <span>Class: <a href="{local:getfacetlink('class',$class,xs:boolean(0))}">{$class}&nbsp; </a> </span>
			else ()}
		{if ($order) 
			then <span>Order: <a href="{local:getfacetlink('order',$order,xs:boolean(0))}">{$order}&nbsp; </a> </span>
			else ()}
		{if ($family) 
			then <span>Family: <a href="{local:getfacetlink('family',$family,xs:boolean(0))}">{$family}&nbsp; </a> </span>
			else ()}
		{if ($wikilink) 
			then <span><a href="{$wikilink}">Wikipedia</a> </span>
			else ()}	
		</p>
		{if ($conservation_status/text()) 
			then <p>Conservation Status: {$conservation_status}</p> 
			else ()}
		<p>{local:getinfo($taxon)//info:info}</p>
	</div>
};

declare function local:tradeaggr($doc) {
	let $taxon := fn:distinct-values($doc//tr:Taxon)
	let $trades := $doc//tr:trade[tr:Taxon eq $taxon]
	let $years := fn:distinct-values($trades/tr:Year)
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
			let $cap-first := for $word in $words
				return fn:string-join((fn:upper-case(fn:substring($word, 1,1)),fn:substring($word, 2)))
			return <th style="text-align:center">{fn:string-join($cap-first, ' ') }</th>
	let $details :=
		for $year in $years
			let $trades_other := $trades[tr:Year eq $year and tr:Term eq $terms_other]
			let $quantity_other := fn:sum($trades_other/tr:Quantity)
			let $quantities := 
				for $term in $terms_restricted
					let $quantity := fn:sum($trades[tr:Year eq $year and tr:Term eq $term]/tr:Quantity)
					return <td style="text-align:center">{$quantity}</td> 
			order by -$year
			return
				  <tr>
				  <td style="text-align:center">{$year}</td>
				  <td style="text-align:center">{fn:sum($trades[tr:Year eq $year]/tr:Quantity)}</td>
				  {$quantities}
				  {if ($show_other)
				  	then <td style="text-align:center">{$quantity_other}</td>
				  	else ()
				  }
				  </tr>
				    

	return <div>
		{local:getinfohtml($doc)}
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



declare function local:tradedetails($doc) {
	let $taxa := fn:distinct-values($doc//tr:Taxon)
	let $class := fn:distinct-values($doc//tr:Class)
	let $order := fn:distinct-values($doc//tr:Order)
	let $family := fn:distinct-values($doc//tr:Family)
	(:Loop through taxa:)
	let $taxa-trades :=
		for $taxon in $taxa
		let $trades := $doc//tr:trade[tr:Taxon eq $taxon]
		let $details := 
			for $trade in $trades
			let $year := $trade/tr:Year
			let $from := $trade/tr:Exporter
			let $purpose := local:getpurpose($trade)
			let $source := local:getsource($trade)
			let $quantity := $trade/tr:Quantity
			order by -$year
			return
				  <tr>
				    <td style="text-align:center">{$year}</td>
				    <td style="text-align:center">{$quantity}</td> 
				    <td>{$source}</td>
				    <td>{$purpose}</td>
				  </tr>
		return <div>
			{local:getinfohtml($doc)}
			<b>Imports into the UK:</b>
			<table style="width:100%" class= "table">
				<tr>
				    <th style="text-align:center">Year</th>
				    <th style="text-align:center">Quantity</th> 
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
	let $items :=
		for $result in $results//search:result
			let $uri := fn:data($result/@uri)
			let $doc := fn:doc($uri)
			return 
			if ($agg eq "on") then
				local:tradeaggr($doc)
			else
				local:tradedetails($doc)
	return 
		if ($items)
		then 
			<div>
				<div>{local:pagination($results)}</div>
				<div class="row">
					<div class="col-md-9">
						<p>Search took: {xdmp:elapsed-time()}</p>
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
				<a class="navbar-brand" href="/index.xqy">CITES Imports into Great Britain</a>
			</div>
			<div id="navbar" class="collapse navbar-collapse">
				<ul class="nav navbar-nav">
					<li class="active"><a href="/index.xqy">Home</a></li>
					<li><a href="#about">About</a></li>
					<li><a href="#contact">Contact</a></li>
				</ul>
			</div><!--/.nav-collapse -->
		</div>
	</nav>

	<div class="container">

		<div class="main">
			<div class="row">
				<div class="col-md-3">
					<h2>Menus And Stuff</h2>
					{local:facets()}
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