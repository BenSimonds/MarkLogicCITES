# csv2xml.py
# FB - 201010107
# First row of the csv file must be header!

# example CSV file: myData.csv
# id,code name,value
# 36,abc,7.6
# 40,def,3.6
# 9,ghi,6.3
# 76,def,99

import csv
import operator

csvFile = 'rawdata/comptab_2015-06-19 09-39_comma_separated.csv'
splitlevel = 'Year'
toplevel = 'trades'
rowlevel = 'trade'

csvData = csv.reader(open(csvFile))
tags = next(csvData)
for i in range(len(tags)):
            tags[i] = tags[i].replace(' ', '_').replace('.', '')
print(tags)
familyindex = tags.index(splitlevel)
print(familyindex)
csvData = sorted(csvData, key=operator.itemgetter(familyindex), reverse=False)

# there must be only one top-level tag
currentfamily = ''
prevfamily = ''
for row in csvData:
    #We want to split our big csv file up into a number of smaller xml files. family seems like a good dimension to split on, as we will use this for species specific pages?
    #Start a new file each time current family changes.
    if row[familyindex] == '':
        currentfamily = row[tags.index(splitlevel)]
    else:   
        currentfamily = row[familyindex].replace(' ', '_').replace('.', '')
    #print("Current Family: " + currentfamily)
    if currentfamily != prevfamily:
        #End the current xml file:
        try:
            xmlData.write('</' + toplevel + '>' + "\n")
            xmlData.close()
        except NameError:
            pass
        #Start a new xml file:
        xmlFile = 'xmldata/trades/' + currentfamily + '.xml'
        xmlData = open(xmlFile, 'w')
        xmlData.write('<?xml version="1.0"?>' + "\n")
        xmlData.write('<' + toplevel + ' xmlns="http://BIPB.com/CITES">' + "\n")
        #Write our first line to it.
        xmlData.write('    <' + rowlevel + '>' + "\n")
        for i in range(len(tags)):
            xmlData.write('        ' + '<' + tags[i] + '>' + row[i] + '</' + tags[i] + '>' + "\n")
        xmlData.write('    </' + rowlevel + '>' + "\n")
        # Update prevfamily:
        prevfamily = currentfamily
    else:
        #continue writing to existing file.
        xmlData.write('    <' + rowlevel + '>' + "\n")
        for i in range(len(tags)):
            xmlData.write('        ' + '<' + tags[i] + '>' + row[i] + '</' + tags[i] + '>' + "\n")
        xmlData.write('    </' + rowlevel + '>' + "\n")

#Close Last File:
xmlData.write('</' + toplevel + '>' + "\n")
xmlData.close()
