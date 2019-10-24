### SETUP ###

rm(list = ls())

if (!'chicago' %in% strsplit(getwd(), "/")[[1]]) {
  setwd('chicago')
}

source("params.R")

libs <- c("tidyverse", "tigris", "rgdal", "leaflet", "leaflet.extras", "RColorBrewer")
ipak(libs)

### SHOOTINGS BY TRACT (ALL) ###

chi_tsa <- read_csv(chi_tsa_path)
chi_tracts <- readOGR(chi_tracts_path)
sum(chi_tsa$count)

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

### SHOOTINGS BY DISTRICT (ALL) ###

chi_dsa <- read_csv(chi_dsa_path)
chi_districts <- readOGR(chi_districts_path)
chi_mapping <- read_csv(chi_geoid_cor_path)

chi_dsa_geo <- geo_join(chi_districts, chi_dsa, "id", "id")

popup <- paste0("GEOID: ", chi_dsa_geo$id, "<br>", "Shootings: ", chi_dsa_geo$count)
pal <- colorNumeric(
  palette = "YlGnBu",
  domain = chi_dsa_geo$count)

chi_dsa_map <- leaflet() %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addPolygons(data = chi_dsa_geo, 
              fillColor = ~pal(count), 
              color = "#b2aeae", # you need to use hex colors
              fillOpacity = 0.7, 
              weight = 1, 
              smoothFactor = 0.2,
              popup = popup)
chi_dsa_map

### CLUSTERS ###

clusters <- read_csv(clusters_path, col_names=FALSE)
ids <- read_csv(chi_dgeoid_path, col_names=FALSE) %>% pull(X1)
clusters$id <- ids
colnames(clusters) <- c("cluster", "id")

chi_clusters_geo <- geo_join(chi_districts, clusters, "id", "id")

popup <- paste0("GEOID: ", chi_clusters_geo$id, "<br>", "Cluster: ", chi_clusters_geo$cluster)
factpal <- colorFactor(brewer.pal(5, "Set1"), chi_clusters_geo$cluster)

chi_clusters_map <- leaflet() %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addPolygons(data = chi_clusters_geo, 
              color = ~factpal(cluster), # you need to use hex colors
              fillOpacity = 0.7, 
              weight = 1, 
              smoothFactor = 0.2,
              popup = popup)
chi_clusters_map

