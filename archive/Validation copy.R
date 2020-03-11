###Preamble
library(sf)
library(raster)
library(rgdal)
library(rgeos)
library(leaflet)
library(tigris)
library(tidyverse) ###Still works with sf objects!
gang.maps <- load(file = "../02_data/bruhn/gangMaps.rda")


###ASSIGNING TRACTS TO GANGS
gang.maps <- as(gang.maps,'Spatial') #Transform to an SP object too

for (m in 2004:2017) {
  city.blocks <- tracts(17, county = 031, year = 2016) #FOR TRACTS
  gang.maps <- spTransform(gang.maps,proj4string(city.blocks))
  #city.blocks <- block_groups(17, county = 031, year = 2017) #FOR BLOCK GROUPS
  k <- length(city.blocks$GEOID) ##Number of blockgroups in Cook County
  placeholder <- gang.maps[gang.maps$year==m,]
  n <- length(placeholder$gang)
  geoids <- city.blocks$GEOID
  overlap <- matrix(NA, nrow=n, ncol=(k)) 
  
  for (i in 1:n) {
    placeholder <- gang.maps[gang.maps$year==m,]
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
  assign(paste0("overlap_", m), overlap)
}

map5 <- leaflet() %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addPolygons(data = modified2) %>%
  addMarkers(lng = -87.553932489999994, lat =41.726432010000003)
map5



