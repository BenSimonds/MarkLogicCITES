Description:
============
An application that uses data from the [CITES trades database](http://trade.cites.org/ "CITES Trades") and [Wikipedia](http://en.wikipedia.org) to provide a search tool for looking through and analysing imports of endangered species into the UK (with potential to expand the data to other countries as well.

Aims:
=====

1. Build a MarkLogic database and associated app that shows data about trades of endangered animals into and out of Britain.
2. Provide a search tool for finding out about different species, and some analysis of which are the most traded, different exporters etc.
3. Tie in with images, wikipedia data, scraped with beautiful soup and added to the db or just referenced externally.

Tasks:
======
- ML Tasks
	- Create db, forests, insert data.-DONE
	- Create app server.-DONE
- App Tasks:														/
	- Create xquery app (similar to ML top songs)-DONE
		- Pages: 						
			- index (main search page)-DONE
				-Need to work on options for search to return better parsable results.	-DONE
			- advanced search
			- record specific result with images, extra data.	-DONE
- Data Tasks:
	- Download some data from CITES database. -DONE
	- Parse into XML (probably in python). 	-DONE
	- Scrape some images for each species with beautiful soup.-DONE
	- Scrape some data from wikipedia.-DONE
	- Map common name to species data for better headings and search. -DONE

