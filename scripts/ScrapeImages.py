from bs4 import BeautifulSoup
import requests
import ssl
import urllib3
import certifi
import re
import csv
import codecs
import os

http = urllib3.PoolManager(
	cert_reqs = 'CERT_REQUIRED',
	ca_certs = certifi.where(),)

#Load list of taxa:
csvFile = 'rawdata/comptab_2015-06-19 09-39_comma_separated.csv'
csvData = csv.reader(open(csvFile))
taxa = []
for row in csvData:
	taxon = {
		'taxon': row[2],
		'class': row[3],
		'order': row[4],
		'family': row[5],
		'genus': row[6],
		'uri': row[2]
	}
	if taxon['taxon'] == 'Taxon':
		#skip first line:
		continue
	elif taxon['taxon'].endswith(' spp.'):
		taxon['taxon'] = taxon['taxon'].rsplit(' ', 1)[0]
	if taxon not in taxa:
		taxa.append(taxon)
#print(taxa)
#print(len(taxa))	
#lets run on a subset of the first 100...
#taxa = ['Macaca fascicularis'] #This will be replaced with a list from my data later on.
taxa = taxa[2001:]


for taxon in taxa:
	#Check it hasnt been done already:
	if os.path.isfile('xmldata/taxa/' + taxon['uri'] + '.xml'):
		continue
	print("Getting data for: " + taxon['taxon'])
	terms = taxon['taxon'].replace(' ','+')
	url = 'https://en.wikipedia.org/w/index.php?search=' + terms

	data = requests.get(url).text

	soup = BeautifulSoup(data)

	
	#Test we got redirected to an entry, not to search results:
	try:
		propername = str(soup.find_all('h1',id='firstHeading')[0].text)
		if propername == 'Search Results':
			# No entry for that species. Try the genus instead.
				url = 'https://en.wikipedia.org/w/index.php?search=' + taxon['genus']
				data = requests.get(url).text
				soup = BeautifulSoup(data)
				propername = str(soup.find_all('h1',id='firstHeading')[0].text)
				#give up if we still get search results:
				if propername == 'Search results':
					continue #Skip this file...

	except IndexError:
		print("No results found for " + taxon['taxon'])
		propername = ''
		continue
	try:
		infobox = soup.find_all('table','infobox')[0]
		try:
			firstimage = infobox.find_all('img', src = True)[0]
			link = 'http:' + firstimage['src'].split('src=')[-1].split('?')[0]
			#Check link isn't to a conservation status thumbnail.
			if 'Status_iucn' in link:
				img_uri = ''
				pass
			else:	
				#Set output filename
				filename = 'rawdata/img/' + taxon['uri']+ '.' + link.rsplit('.',1)[-1]
				#Download image.
				download  = http.urlopen('GET',link).data
				output = open(filename, 'wb')
				output.write(download)
				output.close()
				img_uri = 'img/' + taxon['uri'] + '.' + link.rsplit('.',1)[-1] 
		except IndexError:
			print("No images found in infobox for species: " + taxon['taxon'])
	except IndexError:
		print("No infobox found for species: " + taxon['taxon'])
		
		
	#Write an xml file to go with the species.	
	#Grab the summary text and some other info.:
	try:
		info = soup.find_all('div',{'id':'mw-content-text'})[0].find_all('p',recursive=False)[0].text
		info = re.sub('\[[0-9]*\]','',info).replace('&','')
		try:
			info.encode('ascii', 'ignore')
		except UnicodeEncodeError:
			pass
		#print(info)
	except IndexError:	
		print('Couldnt find info...')
		info = ''
	try:
		wikilink = soup.find_all('head')[0].find_all('link',{'rel':'canonical'})[0]['href']
		print(wikilink)
	except IndexError:
		wikilink = ''
	try:	
		#Find conservation status:
		cs_link = soup.find_all('a',{'href':'/wiki/Conservation_status'})[0]
		cs_status = cs_link.parent.parent.find_next_siblings('tr')[0].find_all('a')[0].text
	except IndexError:		
		cs_status = ''

	#Start a new xml file:
	xmlFile = 'xmldata/taxa/' + taxon['uri'] + '.xml'
	xmlData = codecs.open(xmlFile, encoding='utf-8', mode='w+')
	xmlData.write('<?xml version="1.0"?>' + "\n")
	xmlData.write('<taxon xmlns="http://BIPB.com/CITES/taxa">' + "\n")
	#Write data:
	xmlData.write('    <common_name>' + propername + '</common_name>' + "\n")
	xmlData.write('    <wikilink>' + wikilink + '</wikilink>' + "\n")
	xmlData.write('    <info>' + info + '</info>' + "\n")
	xmlData.write('    <conservation_status>' + cs_status + '</conservation_status>' + "\n")
	xmlData.write('    <img_uri>' + img_uri + '</img_uri>' + "\n")
	xmlData.write('</taxon>' + "\n")
	xmlData.close()


