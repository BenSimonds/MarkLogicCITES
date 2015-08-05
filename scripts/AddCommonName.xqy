xquery version "1.0-ml";
declare namespace html = "http://www.w3.org/1999/xhtml";
declare namespace tr = "http://BIPB.com/CITES";
declare namespace info = "http://BIPB.com/CITES/taxa";

declare variable $docs := (fn:collection("Trades"));

for $d in $docs
  let $taxon := fn:distinct-values($d//tr:Taxon/text())
  let $info_uri := fn:string-join(("taxa/" , $taxon, '.xml'))
  let $info_doc := fn:doc($info_uri) 
  let $common_name := <Common_Name xmlns="http://BIPB.com/CITES"> {$info_doc//info:common_name/text()} </Common_Name>
  for $trade in $d//tr:trade/tr:Taxon
  return
    xdmp:node-insert-after(
      $trade,
      $common_name
    )
