library(readr)
library(tidyverse)
library(lubridate)
library(leaflet)
library(leaflet.extras)
library(htmltools)
library(htmlwidgets)
library(mapview)
library(tigris)
library(acs)
library(stringr)
library(sf)
library(sp)
library(rgeos)
library(rgdal)
library (maptools)
library(spdep)
library(raster)



###Begin by loading the data

violence <- read_csv("violence_tracts.csv")

###Merging Geographic and Violence Data

violence$dummy <- ifelse(violence$event.count > 0,1,0)
cook.blocks <-  tracts("Illinois",county = "031", year = "2016")
violence.geo <- geo_join(cook.blocks, violence, "GEOID", "GEOID")

##Violence Dummy Map
popup <- paste0("GEOID: ", violence.geo$GEOID, "<br>", "Violence Present", violence.geo$dummy)
pal <- colorNumeric(
  palette = "YlGnBu",
  domain = violence.geo$dummy)

map4 <- leaflet() %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addPolygons(data = violence.geo, 
              fillColor = ~pal(dummy), 
              color = "#b2aeae", # you need to use hex colors
              fillOpacity = 0.7, 
              weight = 1, 
              smoothFactor = 0.2,
              popup = popup) %>%
  addLegend(pal = pal, 
            values = violence.geo$dummy, 
            position = "bottomright", 
            title = "Violent Events in the dataset for all Block Groups") 

map4

###Violence Total Map
popup <- paste0("GEOID: ", violence.geo$GEOID, "<br>", "Violence Present", violence.geo$event.count)
pal <- colorNumeric(
  palette = "YlGnBu",
  domain = violence.geo$event.count)

map3 <- leaflet() %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addPolygons(data = violence.geo, 
              fillColor = ~pal(event.count), 
              color = "#b2aeae", # you need to use hex colors
              fillOpacity = 0.7, 
              weight = 1, 
              smoothFactor = 0.2,
              popup = popup) %>%
  addLegend(pal = pal, 
            values = violence.geo$event.count, 
            position = "bottomright", 
            title = "Event Count Per District") 

map3

##############Just Chicago (Not Cook County) ##############
require(rgdal)
Chicago <- readOGR(".","Chicago")

###Checking to see that Chicago shapefile is Chicago

mapChicago <- leaflet() %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addPolygons(data = Chicago)

mapChicago

###Attempt at removing non-intersecting parts of Cook County (raster)
spTransform(violence.geo,proj4string(Chicago))  #slightly confused as to whether this works or not?
proj4string(Chicago) <- proj4string(violence.geo)  #Changing the CRS to match
violence.Chicago <- intersect(violence.geo,Chicago)  ##reduces number of blocks from 1319 to 870
sum(violence.Chicago$dummy) ##down to 787 total tracts with violence, don't quite see how though... look at map

###Checking to see whether it worked or not
popup <- paste0("GEOID: ", violence.Chicago$GEOID, "<br>", "Violence Present", violence.Chicago$dummy)
pal <- colorNumeric(
  palette = "YlGnBu",
  domain = violence.Chicago$dummy)

mapChicago2 <- leaflet() %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addPolygons(data = violence.Chicago, 
              fillColor = ~pal(dummy), 
              color = "#b2aeae", # you need to use hex colors
              fillOpacity = 0.7, 
              weight = 1, 
              smoothFactor = 0.2,
              popup = popup) %>%
  addLegend(pal = pal, 
            values = violence.Chicago$dummy, 
            position = "bottomright", 
            title = "Violent Events in the dataset for all Block Groups") 

mapChicago2

###Adjacency Matrix
#Not working for some reason
adjacency <- gTouches(cook.blocks,byid = T)
#Alternate attempt
adjacency <- poly2nb(violence.Chicago, row.names = violence.Chicago$GEOID, queen = T)


###Code for Merging Districts
#First create percentiles for amount of violence in each district
violence.Chicago$vio.percentile <- rank(violence.Chicago$event.count, ties.method = "max")/nrow(violence.Chicago)
#Second find number of districts with no violence in them
nullviolence <- nrow(violence.Chicago)-sum(violence.Chicago$dummy)
nullviolence <- violence.Chicago[violence.Chicago@data$dummy == 0,]
#Loop though those and merge them if they are adjacent to another district with no violence
for (i in 1:nullviolence){
  
}


####Old Attempts
#Now to determione adjacency by creating a list of neighbors for each polygon
adjacency <- poly2nb(income_merged, row.names = income_merged$GEOID, queen = T)

##Now to create distance measures (Returns bizarre measurements, unclear why)
#Centroid Cooridnates
centers <- gCentroid(income_merged, byid = T)
centers <- spTransform(centers, CRS("+init=epsg:2062")) 
centroid.distance <- gDistance(centers, byid = T)

#Alternatively to create an adjacency matrix use the following command >> gTouches(income_merged, byid=T)

