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


#Now to determione adjacency by creating a list of neighbors for each polygon
adjacency <- poly2nb(income_merged, row.names = income_merged$GEOID, queen = T)

##Now to create distance measures (Returns bizarre measurements, unclear why)
#Centroid Cooridnates
centers <- gCentroid(income_merged, byid = T)
centers <- spTransform(centers, CRS("+init=epsg:2062")) 
centroid.distance <- gDistance(centers, byid = T)

#Alternatively to create an adjacency matrix use the following command >> gTouches(income_merged, byid=T)

