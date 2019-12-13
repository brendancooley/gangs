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
				   "cp " + templatesPath + "cooley-latex-beamer.tex" + " templates/",
				   "cp " + templatesPath + "cooley-paper-template.latex" + " templates/",
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
		fName = figsFiles[i].split("/")[1].split(".")[0]
		suffix = figsFiles[i].split("/")[1].split(".")[1]
		if suffix == "tex":
			yield {
				'name': figsFiles[i],
				'actions':["cd figs/;  latexmk -pdf " + fName + ".tex" + "; latexmk -c; magick -density 300 " + fName + ".pdf " + fName + ".png"]
			}

def task_paper():
	"""

	"""
	if os.path.isfile("references.RData") is False:
		yield {
			'name': "collecting references...",
			'actions':["R --slave -e \"set.seed(100);knitr::knit('gangs.rmd')\""]
        }
	yield {
    	'name': "writing paper...",
    	'actions':["R --slave -e \"set.seed(100);knitr::knit('gangs.rmd')\"",
                   "pandoc --template=templates/cooley-paper-template.latex --filter pandoc-citeproc -o gangs.pdf gangs.md"],
                   'verbosity': 2,
	}

def task_slides():
	yield {
		'name': "building slides...",
		'actions':["R --slave -e \"rmarkdown::render(\'" + "ECO541talk/drugs.rmd" + "\', output_file=\'" + "drugs.pdf" +"\')\""]
	}