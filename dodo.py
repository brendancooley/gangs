import os
import sys

helpersPath = os.path.expanduser("~/Dropbox (Princeton)/11_Workflow")
sys.path.insert(1, helpersPath)

import helpers

sectionsPath = "sections/"
sectionsTemplate = os.path.expanduser("~/Dropbox\ \(Princeton\)/8_Templates/cooley-plain.latex")

def task_sections():
	sectionsFiles = helpers.getFiles(sectionsPath)
	for i in range(len(sectionsFiles)):
		fName = sectionsFiles[i].split(".")[0]
		suffix = sectionsFiles[i].split(".")[1]
		if suffix == "md":
			yield {
				'name': sectionsFiles[i],
				'actions':["pandoc --template=" + sectionsTemplate + " -o " + 
							fName + ".pdf " + sectionsFiles[i]]
			}
