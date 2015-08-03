xquery version "1.0-ml";
module namespace options = "http://BIPB.com/CITES/options";
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";


declare variable $options := 
  <options xmlns="http://marklogic.com/appservices/search">
  <!--
  <constraint name="year">
  	<range type="xs:int">
  		<element ns="http://BIPB.com/CITES" name="Year"/>
  		<facet-option>limit=30</facet-option>
  		<facet-option>descending</facet-option>
  	</range>
  </constraint>
  -->
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
