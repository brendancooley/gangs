### SETUP ###

if (!'chicago' %in% strsplit(getwd(), "/")[[1]]) {
  setwd('chicago')
}

source("params.R")

libs <- c("tidyverse", "leaflet", "leaflet.extras")

### SHOOTINGS BY TRACT (ALL) ###

chi_tsa <- read_csv(chi_tsa_path)
chi_tracts <- readOGR(chi_tracts_path)

chi_tsa_geo <- geo_join(chi_tracts, chi_tsa, "GEOID", "GEOID")

popup <- paste0("GEOID: ", chi_tsa_geo$GEOID, "<br>", "Shootings: ", chi_tsa_geo$count)
pal <- colorNumeric(
  palette = "YlGnBu",
  domain = chi_tsa_geo$count)

chi_tsa_map <- leaflet() %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addPolygons(data = chi_tsa_geo, 
              fillColor = ~pal(count), 
              color = "#b2aeae", # you need to use hex colors
              fillOpacity = 0.7, 
              weight = 1, 
              smoothFactor = 0.2,
              popup = popup)
chi_tsa_map
