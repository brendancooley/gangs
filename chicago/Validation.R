###Preamble
setwd("~/Desktop/gangs/chicago")
library(sf)
library(raster)
library(rgdal)
library(rgeos)
library(leaflet)
library(tidyverse) ###Still works with sf objects!
gang.maps <- load(file = "/Bruhn Data/gangMaps.rda")


###Testing to see if the Data works
gangs2017 <- filter(gang.maps,year==2017)

popup <- paste0("Gang: ", gangs2017$gang)
map4 <- leaflet() %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addPolygons(data = gangs2017, 
              popup = popup)
  
map4

###ASSIGNING TRACTS TO GANGS
library(tigris)
library(rgdal)
city.blocks <- block_groups(17, county = 031, year = 2017) #an SP object (3,993 block groups)
city.blocks <- tracts(17,county = 031, year = 2017) #1319 tracts
gang.maps.sf <- gang.maps
gang.maps <- as(gang.maps,'Spatial') #Transform to an SP object too
gang.maps <- spTransform(gang.maps,proj4string(city.blocks))


n <- 53                        ##Number of gangs in 2017
k <- length(city.blocks$GEOID) ##Number of blockgroups in Cook County
overlap <- matrix(NA, nrow=n, ncol=(k)) 
geoids <- city.blocks$GEOID

for (i in 1:n) {
  placeholder <- gang.maps[gang.maps$year==2017,]
  gang.names <- unique(placeholder$gang)
  placeholder <- placeholder[placeholder$gang==gang.names[i],]
  placeholder <- spTransform(placeholder, CRSobj = "+proj=moll")
  placeholder <- gBuffer(placeholder, byid = T, width = -1)
  placeholder <- spTransform(placeholder, CRSobj = proj4string(city.blocks))
  for (j in 1:k) {
    city.placeholder <- city.blocks[city.blocks$GEOID==geoids[j],]
    if(gIntersects(placeholder,city.placeholder)){
      testing <- gIntersection(placeholder,city.placeholder)
      # if(length(testing$year)>0){
      #   overlap[i,j] <- area(testing)/area(city.blocks[city.blocks$GEOID==geoids[j],])
      #   print("hello")
      # }
      # else{
      #   overlap[i,j] <- 0
      # }
      print(area(testing))
      overlap[i,j] <- area(testing)/area(city.blocks[city.blocks$GEOID==geoids[j],])
      }
      
    else{
      overlap[i,j] <- 0
    }
  }
}


map5 <- leaflet() %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addPolygons(data = modified2) %>%
  addMarkers(lng = -87.553932489999994, lat =41.726432010000003)
map5



