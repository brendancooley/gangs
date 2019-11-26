### SETUP ###

rm(list = ls())

if (!'chicago' %in% strsplit(getwd(), "/")[[1]]) {
  setwd('chicago')
}

source("params.R")

libs <- c("tidyverse", "tigris", "leaflet", "leaflet.extras", "tmap", "rgdal", "RColorBrewer")
ipak(libs)

### DATA ###

chi_clean <- read_csv(chi_clean_path)
minY <- min(chi_clean$year) %>% year()
maxY <- max(chi_clean$year) %>% year()

nc <- read_csv(nc_path, col_names=FALSE) %>% pull(.) # noise cluster

clusters <- read_csv(clusters_path, col_names=FALSE) %>% pull(.)
geoid_keep <- read_csv(geoid_keep_path, col_names=FALSE) %>% pull(.)
geoid_zero <- read_csv(geoid_zero_path, col_names=FALSE) %>% pull(.)

clusters_keep_df <- data.frame(clusters, geoid_keep)
colnames(clusters_keep_df) <- c("cluster", "GEOID")
zero_df <- data.frame(nc, geoid_zero)
colnames(zero_df) <- c("cluster", "GEOID")

clusters_df <- bind_rows(clusters_keep_df, zero_df) %>% as_tibble()
clusters_df$cluster <- as.factor(clusters_df$cluster)

chi_tracts <- readOGR(chi_tracts_path)

### CLUSTERS ###

chi_clusters_geo <- geo_join(chi_tracts, clusters_df, "GEOID", "GEOID")

tmap_style("white")
chi_clusters_map <- tm_shape(chi_clusters_geo) +
  tm_polygons("cluster", title=paste0("Cluster ID"), palette="Set3") +
  tm_layout(legend.position=c("left", "bottom"))

save_tmap(chi_clusters_map, "figs/chi_clusters_map.png")


# 
# popup <- paste0("GEOID: ", chi_clusters_geo$GEOID, "<br>", "Cluster: ", chi_clusters_geo$cluster)
# factpal <- colorFactor(brewer.pal(5, "Set1"), chi_clusters_geo$cluster)
# display.brewer.pal(5, "Set1")
# 
# chi_clusters_map <- leaflet() %>%
#   addProviderTiles(providers$CartoDB.Positron) %>%
#   addPolygons(data = chi_clusters_geo, 
#               color = ~factpal(cluster), # you need to use hex colors
#               fillOpacity = 0.7, 
#               weight = 1, 
#               smoothFactor = 0.2,
#               popup = popup)
# chi_clusters_map
