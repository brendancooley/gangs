# -*- coding: utf-8 -*-
"""
Spyder Editor

This is a temporary script file.
"""

import csv
import scraperwiki
url = 'http://www.slmpd.org/Crimereports.shtml'
data = scraperwiki.scrape(url)
data = data.splitlines()
reader = csv.DictReader(data)
for record in reader:
   print record
   #for scraperwiki only:
   scraperwiki.sqlite.save(['Value'], record)