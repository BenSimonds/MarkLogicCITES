xquery version "1.0-ml";
module namespace facets = "http://BIPB.com/CITES/facets";
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";

declare function facets-all() {
  for $f in ("Class","Order","Family","Taxon","Common_Name")
    let $value := xdmp:get-request-field($f,())
    where $value
    return <facets:facet name="{$f}" qname="{fn:string-join(("tr:",$f))}">{$value}</facets:facet>
};

declare function facets($results)
{
  for $facet in $results//search:facet
  	let $facet-name := $facet/@name/string()
  	let $facet-values :=
  		for $facet-value in $facet/search:facet-value
  			let $value-name := 
  				if ($facet-value/@name/string())
  				then xs:string($facet-value/@name/string())
  				else xs:string("Unknown")
  			let $value-count := $facet-value/@count
  			let $value-text :=
  				if ($value-count >= 1000)
  				then fn:string-join((xs:string(fn:floor($value-count div 1000)) , "k+"))
  				else $value-count/string()
  			order by $value-name	
  			return <li class="list-group-item"> <a href="{getfacetlink($facet-name,$facet-value,xs:boolean(1))}">{$value-name}</a><span class="badge">{$value-text}</span></li> 
  	return
  		<div class="facet">
  			<h3 style="text-transform:capitalize">{$facet-name}</h3>
  			<ul class="list-group">{$facet-values}</ul>
  		</div>
};

declare function getfacetlink($facet as xs:string, $value as xs:string, $include as xs:boolean) as xs:string{
  let $value-clean := fn:replace(fn:replace($value,"[\s]","+"),'\W','')
  let $agg := xdmp:get-request-field("agg", "off")
  let $q-text := xdmp:get-request-field("q", "")
  let $facet-strings :=
    for $f in facets-all()
    where $f/@name ne $facet
    return fn:string-join(('&amp;',$f/@name,'=',$f/text()))
  let $link-string := fn:string-join(("&amp;",$facet,"=",$value-clean))
  let $link :=
    if ($include)
    then fn:string-join(('http://localhost:8050/index.xqy?q=', $q-text, $link-string, $facet-strings, '&amp;agg=',$agg))
    else fn:string-join(('http://localhost:8050/index.xqy?q=', $link-string, '&amp;agg=',$agg))
    return $link
};
