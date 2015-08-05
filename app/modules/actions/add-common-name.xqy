xquery version "1.0-ml";

import module namespace cpf = "http://marklogic.com/cpf"
  at "/MarkLogic/cpf/cpf.xqy";

declare namespace this = "/cpf/xfdl-conversion/actions/normalize-xml-to-ground-schema.xqy";
declare namespace tr = "http://BIPB.com/CITES";
declare namespace info = "http://BIPB.com/CITES/taxa";

declare variable $cpf:document-uri as xs:string external;
declare variable $cpf:transition as element() external;
declare variable $cpf:options as node() external;

try {
  (: Make sure the normalization config file is loaded :)
  let $uri := $cpf:document-uri
  let $doc := fn:doc($uri)
  let $taxon := fn:distinct-values($doc/tr:Taxon/text())
  let $taxon_score := fn:replace($taxon, ' ', '_')
  let $info_uri := fn:string-join(("taxa/" , $taxon_score, '.xml'))
  let $info_doc := fn:doc($info_uri) 
  let $common_name := <Common_Name xmlns="http://BIPB.com/CITES"> {$info_doc//info:common_name/text()} </Common_Name>
  return
    (xdmp:node-insert-after(
      $doc//tr:Taxon,
      $common_name
    ),
    cpf:success($cpf:document-uri, $cpf:transition, ())
    )
  else
      cpf:failure($cpf:document-uri, $cpf:transition, "god knows what went wrong.", ())
} catch ($error) {
  cpf:failure($cpf:document-uri, $cpf:transition, $error, ())
}

(: convert-and-normalize-xfdl.xqy :)