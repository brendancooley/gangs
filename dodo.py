import os
import sys

helpersPath = "source/python/"
sys.path.insert(1, helpersPath)

import helpers

templatesPath = "~/Dropbox\ \(Princeton\)/8_Templates/"
softwarePath = "~/Dropbox\ \(Princeton\)/14_Software/"

sectionsPath = "sections/"
sectionsTemplate = "templates/cooley-plain.latex"

figsPath = "figs/"
figsTemplate = "templates/cooley-plain.latex"

sourcePath = "source/"

def task_source():
	yield {
		'name': "initializing environment...",
		'actions':["cp " + templatesPath + "cooley-plain.latex" + " templates/",
				   "cp -a " + softwarePath + " source/"]
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

def task_figs():
	figsFiles = helpers.getFiles(figsPath)
	for i in range(len(figsFiles)):
		fName = figsFiles[i].split(".")[0]
		suffix = figsFiles[i].split(".")[1]
		if suffix == "md":
			yield {
				'name': figsFiles[i],
				'actions':["pandoc --template=" + figsTemplate + " -o " +
							fName + ".pdf " + figsFiles[i]]
			}
