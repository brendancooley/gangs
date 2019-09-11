import os
import sys

templatesPath = "~/Dropbox (Princeton)/8_Templates/"

sectionsPath = "sections/"
sectionsTemplate = "templates/cooley-plain.latex"

sourcePath = "source/"

def task_source():
	yield {
		'name': "initializing environment...",
		'actions':["cp " + templatesPath + "cooley-plain.latex" + " templates/"]
	}

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
