(:Set Up A MarkLogic DB for my CITES Data - to be run in mark logic query console.:)

(:Create Forest:)
xquery version "1.0-ml";
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";
let $config := admin:get-configuration()
let $config := admin:forest-create(
  $config, 
  "CITES-01",
  xdmp:host(), 
  ())
return admin:save-configuration($config);

(: Create Database :)
xquery version "1.0-ml";
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";
let $config := admin:get-configuration()
let $config := admin:database-create(
  $config,
  "CITES",
  xdmp:database("Security"),
  xdmp:database("Schemas"))
return admin:save-configuration($config);

(: attach forest to database :)
xquery version "1.0-ml";
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";
let $config := admin:get-configuration()
let $config := admin:database-attach-forest(
  $config,
  xdmp:database("CITES"), 
  xdmp:forest("CITES-01"))
return admin:save-configuration($config);

(: Create application server :)
xquery version "1.0-ml";
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";
let $config := admin:get-configuration()
let $groupid := admin:group-get-id($config, "Default")
let $server := admin:http-server-create(
  $config, 
  $groupid,
  "8050-CITES", 
  "C:\Users\ben.simonds\Documents\Marklogic CITES\app",
  8050,
  0,
  admin:database-get-id($config, "CITES"))
return admin:save-configuration($server);


(:Create Forest For Triggers:)
xquery version "1.0-ml";
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";
let $config := admin:get-configuration()
let $config := admin:forest-create(
  $config, 
  "CITES-01-Triggers",
  xdmp:host(), 
  ())
return admin:save-configuration($config);

(: Create Database :)
xquery version "1.0-ml";
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";
let $config := admin:get-configuration()
let $config := admin:database-create(
  $config,
  "CITES-Triggers",
  xdmp:database("Security"),
  xdmp:database("Schemas"))
return admin:save-configuration($config);

(: attach forest to database :)
xquery version "1.0-ml";
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";
let $config := admin:get-configuration()
let $config := admin:database-attach-forest(
  $config,
  xdmp:database("CITES-Triggers"), 
  xdmp:forest("CITES-01-Triggers"))
return admin:save-configuration($config);



(:Create Forest For Modules:)
xquery version "1.0-ml";
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";
let $config := admin:get-configuration()
let $config := admin:forest-create(
  $config, 
  "CITES-01-Modules",
  xdmp:host(), 
  ())
return admin:save-configuration($config);

(: Create Database :)
xquery version "1.0-ml";
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";
let $config := admin:get-configuration()
let $config := admin:database-create(
  $config,
  "CITES-Modules",
  xdmp:database("Security"),
  xdmp:database("Schemas"))
return admin:save-configuration($config);

(: attach forest to database :)
xquery version "1.0-ml";
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";
let $config := admin:get-configuration()
let $config := admin:database-attach-forest(
  $config,
  xdmp:database("CITES-Modules"), 
  xdmp:forest("CITES-01-Modules"))
return admin:save-configuration($config);