xquery version "1.0-ml";
module namespace facets = "http://BIPB.com/CITES/facets";
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";



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
  let $agg := xdmp:get-request-field("agg", "off")
  let $q-text := xdmp:get-request-field("q", "sort:alphabetical")
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
