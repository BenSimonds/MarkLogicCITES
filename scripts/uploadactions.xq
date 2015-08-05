xquery version "1.0-ml"; 
import module namespace info = "http://marklogic.com/appservices/infostudio" at "/MarkLogic/appservices/infostudio/info.xqy";

let $path := "C:\Users\ben.simonds\Documents\MarklogicCITES\app\modules\actions"
let $options := 
  <options xmlns="http://marklogic.com/appservices/infostudio">
    <uri>
      <literal>/modules/actions/add-common-name.xqy</literal>
      <filename/>
      <literal>.</literal>
      <ext/>
    </uri>
    <max-docs-per-transaction>100</max-docs-per-transaction>
    <error-handling>continue-with-warning</error-handling>
    <overwrite>overwrite</overwrite>
  </options>
let $database := "CITES-Modules"
return info:load($path, (), $options, $database);


"CPF Actions Loaded to Modules Database"