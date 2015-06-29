(: Load Documents:)

(: Load trade data in Batches of 1000:)



xdmp:eval('for $d in xdmp:filesystem-directory("C:\Users\ben.simonds\Documents\Marklogic CITES\xmldata\trades")//dir:entry[4001 to 4781]
  return xdmp:document-load($d//dir:pathname, 
    <options xmlns="xdmp:document-load">
      <uri>trades/{fn:string($d//dir:filename)}</uri>
      <collections>
        <collection>Trades</collection>
      </collections>
    </options>)',  (),
        <options xmlns="xdmp:eval">
          <database>{xdmp:database("CITES")}</database>
        </options>)

(: Load taxa info:)
xdmp:eval('for $d in xdmp:filesystem-directory("C:\Users\ben.simonds\Documents\Marklogic CITES\xmldata\taxa")//dir:entry
  return xdmp:document-load($d//dir:pathname, 
    <options xmlns="xdmp:document-load">
      <uri>taxa/{fn:string($d//dir:filename)}</uri>
      <collections>
        <collection>Info</collection>
      </collections>
    </options>)',  (),
        <options xmlns="xdmp:eval">
          <database>{xdmp:database("CITES")}</database>
        </options>)

(:Load Images:) 
xdmp:eval('for $d in xdmp:filesystem-directory("C:\Users\ben.simonds\Documents\Marklogic CITES\rawdata\img")//dir:entry
  return xdmp:document-insert(
    fn:string-join(("img/",$d//dir:filename)),
    xdmp:external-binary($d//dir:pathname),
    xdmp:default-permissions(),
    "Images"
    )',  (),
        <options xmlns="xdmp:eval">
          <database>{xdmp:database("CITES")}</database>
        </options>)      