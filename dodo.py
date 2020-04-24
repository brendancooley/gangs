import os
import sys

helpersPath = "source/python/"
sys.path.insert(1, helpersPath)

import helpers

templatesPath = "~/Dropbox\ \(Princeton\)/8_Templates/"
softwarePath = "~/Dropbox\ \(Princeton\)/14_Software/"
verticatorPath = "~/Dropbox\ \(Princeton\)/8_Templates/plugin/verticator"
pluginDest = "index_files/reveal.js-3.8.0/plugin"
revealPath = "~/Dropbox\ \(Princeton\)/8_Templates/reveal.js-3.8.0"

sectionsPath = "06_sections/"
sectionsTemplate = "templates/cooley-plain.latex"

figsPath = "05_figs/cartoons/"
figsTemplate = "templates/cooley-plain.latex"

website_docs = "~/Dropbox\ \(Princeton\)/5_CV/website/static/docs"
website_docs_github = "~/Github/brendancooley.github.io/docs"

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
		fName = figsFiles[i].split("/")[2].split(".")[0]
		suffix = figsFiles[i].split("/")[2].split(".")[1]
		if suffix == "tex":
			yield {
				'name': figsFiles[i],
				'actions':["cd figs/;  latexmk -pdf " + fName + ".tex" + "; latexmk -c; magick -density 300 " + fName + ".pdf " + fName + ".png; cd ..;"]
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
    	'actions':["cd 06_sections/; R --slave -e \"set.seed(100);knitr::knit('abstract.rmd')\"; cd ..",
    			   "R --slave -e \"set.seed(100);knitr::knit('gangs.rmd')\"",
                   "pandoc --template=templates/cooley-paper-template.latex --filter pandoc-citeproc -o gangs.pdf gangs.md"],
                   'verbosity': 2,
	}

def task_post_to_web():
	"""

	"""
	yield {
		'name': "posting...",
		'actions': ["cp -a gangs.pdf " + website_docs,
					"cp -a gangs.pdf " + website_docs_github]
	}

def task_prep_slides():
	"""

	"""
	yield {
		'name': "moving slide files",
		'actions': ["mkdir -p css",
					"cp -a " + templatesPath + "slides/ " + "css/"]
	}

def task_slides():
	"""

	"""
	yield {
		'name': 'draft slides',
		'actions': ["R --slave -e \"rmarkdown::render('gangs_slides.Rmd', output_file='index.html')\"",
            "perl -pi -w -e 's{reveal.js-3.3.0.1}{reveal.js-3.8.0}g' index.html",
            "cp -r " + revealPath + " index_files/",
            "cp -a " + verticatorPath + " " + pluginDest],
		'verbosity': 2,
	}

def task_ECOslides():
	yield {
		'name': "building slides...",
		'actions':["R --slave -e \"rmarkdown::render(\'" + "ECO541talk/drugs.rmd" + "\', output_file=\'" + "drugs.pdf" +"\')\""]
	}
