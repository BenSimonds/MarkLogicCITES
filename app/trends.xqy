xquery version "1.0-ml";
declare namespace tr = "http://BIPB.com/CITES";
declare namespace pp = "http://BIPB.com/CITES/purposes";
declare namespace sr = "http://BIPB.com/CITES/sources";
declare namespace info = "http://BIPB.com/CITES/taxa";
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";

(:Aim, use some search criteria to generate table of trends in trades:)

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