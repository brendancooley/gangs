### TODO ###

# write csv for violence_tracts

### SETUP ###

if (!'chicago' %in% strsplit(getwd(), "/")[[1]]) {
  setwd('chicago')
}
# getwd()

library(tidyverse)

source("unified.data.R")

###

# chi <- final.data(city, tract.type, micro.length)
violence <- read_csv("data/violence_tracts.csv")

first.year<- as.numeric(substring(names(violence[22]),1,4))
last.year <- as.numeric(substring(names(violence[ncol(violence)]),1,4))-1
construction <- violence[,c(1:21)] #the new dataset being constructed
for(i in first.year:last.year) {
  first.day <- ifelse(i==first.year,22,ifelse((i-1)%%4==0,first.day+367,first.day+366)) #determine first day of the year (column)
  last.day <- ifelse(i%%4==0,first.day+366,first.day+365) #determine last day of the year (column)
  iterations <- 365%/%micro.length #number of internal loops to run
  for(j in 1:iterations) {
    currentmarker <- ifelse(j==1,first.day,currentmarker+micro.length)#first column to be dealt with
    to.be.added <- ifelse(j!=iterations,colnames(violence[c(currentmarker:(currentmarker+micro.length-1))]),
                          colnames(violence[c(currentmarker:last.day)])) #takes one micro-length worth of days to aggregate
    construction$place.holder <- rowSums(violence[to.be.added]) #aggregation step
    names(construction)[names(construction) == "place.holder"] <- paste(i,".",j,sep = "") #rename variable
  }
}

matrix <- construction[,seq(22, ncol(construction))]
ids <- construction[,1]
# colSums(matrix)
# rowSums(matrix)
write_csv(matrix, "output/chi_matrix.csv")
write_csv(ids, "output/chi_ids.csv")
