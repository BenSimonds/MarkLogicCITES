xquery version "1.0-ml";
module namespace tools = "http://BIPB.com/CITES/tools";
declare namespace tr = "http://BIPB.com/CITES";
declare namespace pp = "http://BIPB.com/CITES/purposes";
declare namespace sr = "http://BIPB.com/CITES/sources";
declare namespace info = "http://BIPB.com/CITES/taxa";
import module namespace fc="http://BIPB.com/CITES/facets" at "/facets.xqy";


declare function getquantity($trades) as xs:float {
	let $max := for $trade in $trades/descendant-or-self::tr:trade
		let $importer := xs:float($trade/tr:Importer_reported_quantity/text())
  		let $exporter := xs:float($trade/tr:Exporter_reported_quantity/text())
  		let $max := fn:max(($importer, $exporter))
  		return $max
	return fn:round(fn:sum($max))
  	};

declare function getpurpose($trade) {
	let $code := $trade/tr:Purpose
	let $purpose := fn:doc("purposes.xml")/pp:purposes/pp:purpose[@id eq $code]/text()
	return 
	if ($purpose) then
		$purpose
	else
		"Unknown"
};

declare function getpurpose_code($code) {
	let $purpose := fn:doc("purposes.xml")/pp:purposes/pp:purpose[@id eq $code]/text()
	return 
	if ($purpose) then
		$purpose
	else
		"Unknown"
};

declare function getcountry($code) {
	let $country := fn:doc("countries.xml")//row[code eq $code]/country/text()
	return 
	if ($country) then
		$country
	else
		"Unknown"
};

declare function getsource($trade) {
	let $code := $trade/tr:Source
	let $source := fn:doc("sources.xml")/sr:sources/sr:source[@id eq $code]/text()
	return 
	if ($source) then
		$source
	else
		"Unknown"
};

declare function getsource_code($code) {
	let $source := fn:doc("sources.xml")/sr:sources/sr:source[@id eq $code]/text()
	return 
	if ($source) then
		$source
	else
		"Unknown"
};


declare function getinfo($taxon) {
	let $info_uri := fn:string-join(("taxa/",$taxon,".xml"))
	let $info := fn:doc($info_uri)
	let $c_name := $info//info:common_name/text()
	return $info
};

declare function getimage($taxon) {
	let $uri := getinfo($taxon)//info:img_uri/text()
	return 
	if (fn:doc($uri))
	then <div class="pull-right"><img class="img-rounded img-species" alt="{$taxon}" src="get-file.xqy?uri={$uri}"/></div>
	else ()
};

declare function getinfohtml($doc) {
	let $taxon := fn:distinct-values($doc//tr:Taxon)
	let $class := fn:distinct-values($doc//tr:Class)
	let $order := fn:distinct-values($doc//tr:Order)
	let $family := fn:distinct-values($doc//tr:Family)
	let $common_name := getinfo($taxon)//info:common_name
	let $wikilink := getinfo($taxon)//info:wikilink
	let $conservation_status := getinfo($taxon)//info:conservation_status
	let $c-quoted := fn:string-join(("&#34;",$common_name,"&#34;"))
	let $t-quoted := fn:string-join(("&#34;",$taxon,"&#34;"))
	return
	<div>
		{if (fn:ends-with($taxon, 'spp.'))
			then <h4>{$taxon} (Various Species)<a href="{fc:getfacetlink('taxon',$t-quoted,xs:boolean(0))}">&nbsp;&#x1F517;</a></h4>
		else if ($common_name eq $taxon) 
			then <h4>{$taxon}<a href="{fc:getfacetlink('taxon',$t-quoted,xs:boolean(0))}">&nbsp;&#x1F517;</a></h4>
		else if ($common_name ne '')
			then <h4>{$common_name} ({$taxon})<a href="{fc:getfacetlink('common_name',$c-quoted,xs:boolean(0))}">&nbsp;&#x1F517;</a></h4>
		else <h4>{$taxon}<a href="{fc:getfacetlink('taxon',$t-quoted,xs:boolean(0))}">&nbsp;&#x1F517;</a></h4>}
		{tools:getimage($taxon)}
		<p>
		{if ($class) 
			then <span>Class: <a href="{fc:getfacetlink('class',$class,xs:boolean(0))}">{$class}&nbsp; </a> </span>
			else ()}
		{if ($order) 
			then <span>Order: <a href="{fc:getfacetlink('order',$order,xs:boolean(0))}">{$order}&nbsp; </a> </span>
			else ()}
		{if ($family) 
			then <span>Family: <a href="{fc:getfacetlink('family',$family,xs:boolean(0))}">{$family}&nbsp; </a> </span>
			else ()}
		{if ($wikilink) 
			then <span><a href="{$wikilink}">Wikipedia</a> </span>
			else ()}	
		</p>
		{if ($conservation_status/text()) 
			then <p>Conservation Status: {$conservation_status}</p> 
			else ()}
		<p>{getinfo($taxon)//info:info}</p>
	</div>
};