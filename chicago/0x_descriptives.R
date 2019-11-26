### SETUP ###

rm(list = ls())

if (!'chicago' %in% strsplit(getwd(), "/")[[1]]) {
  setwd('chicago')
}

source("params.R")

libs <- c("tidyverse", "tigris", "leaflet", "leaflet.extras", "tmap", "rgdal", "lubridate")
ipak(libs)

chi_pop <- read_csv(chi_pop_path)
chi_cov <- read_csv(paste0(chi_cov_path_pre, "2016.csv")) %>% select(GEOID, population)
# chi_cov$population %>% sum()  # note that sum of tract-level estimates don't agree with total population of city

chi_clean <- read_csv(chi_clean_path)
minY <- min(chi_clean$year) %>% year()
maxY <- max(chi_clean$year) %>% year()

chi_tha <- read_csv(chi_tha_path)
chi_tsa <- read_csv(chi_tsa_path)
chi_tna <- read_csv(chi_tna_path)
chi_tha <- chi_tha %>% left_join(chi_cov)
chi_tsa <- chi_tsa %>% left_join(chi_cov)
chi_tna <- chi_tna %>% left_join(chi_cov)

# construct hnfs/arrest rates per tract
chi_tha$rate <- chi_tha$count / chi_tha$population
chi_tsa$rate <- chi_tsa$count / chi_tsa$population
chi_tna$rate <- chi_tna$count / chi_tna$population

chi_mat_h <- read_csv(chi_th_matrix_path, col_names=FALSE)
chi_mat_s <- read_csv(chi_ts_matrix_path, col_names=FALSE)
chi_mat_n <- read_csv(chi_tn_matrix_path, col_names=FALSE)

chi_tracts <- readOGR(chi_tracts_path)

### POPULATION BY TRACT ###

chi_pop_geo <- geo_join(chi_tracts, chi_cov, "GEOID", "GEOID")

tmap_style("gray")
chi_pop_map <- tm_shape(chi_pop_geo) +
  tm_polygons("population", title=paste0("Population Estimates, 2016")) +
  tm_layout(legend.position=c("left", "bottom"))
save_tmap(chi_pop_map, "figs/chi_pop_map.png")

### SHOOTINGS AND NARCOTICS ARRESTS OVER TIME ###

homicides_t <- colSums(chi_mat_h)
hnfs_t <- colSums(chi_mat_s)
narcotics_t <- colSums(chi_mat_n)
period_t <- seq(min(chi_clean[[aggregation]]), max(chi_clean[[aggregation]]), by = aggregation)

counts_t <- data.frame(homicides_t, hnfs_t, narcotics_t, period_t) %>% as_tibble()
counts_t$year <- year(counts_t$period_t)
counts_t <- left_join(counts_t, chi_pop)
counts_t$`homicide rate` <- counts_t$homicides_t / counts_t$population * 100000
counts_t$`shooting rate` <- counts_t$hnfs_t / counts_t$population * 100000
counts_t$narcotics_100000 <- counts_t$narcotics_t / counts_t$population * 100000

counts_t_cat <- counts_t %>% gather(key="type", value="rate", `homicide rate`, `shooting rate`, narcotics_100000) %>% filter(type!="narcotics_100000")

hnfs_t_plot <- ggplot(counts_t_cat, aes(x=period_t, y=rate, color=type)) +
  geom_line(alpha=.5) +
  # geom_smooth(method="loess", color="red", se=FALSE) +
  theme_classic() +
  labs(x="Month", y="Homicides and Non-Fatal Shootings per 100,000", title="Chicago Homicides and Non-Fatal Shootings") +
  scale_color_grey() +
  theme(aspect.ratio=1)
ggsave(filename="figs/hnfs_t_plot.png", plot=hnfs_t_plot, width=6, height=6)

narcotics_t_plot <- ggplot(counts_t, aes(x=period_t, y=narcotics_100000)) +
  geom_line(alpha=.5) +
  geom_smooth(method="loess", color="red", se=FALSE) +
  theme_classic() +
  labs(x="Month", y="Narcotics Arrests per 100,000", title="Chicago Narcotics Arrests") +
  theme(aspect.ratio=1)
ggsave(filename="figs/narcotics_t_plot.png", plot=narcotics_t_plot, width=6, height=6)

### SHOOTINGS BY TRACT (ALL) ###

chi_tsa_geo <- geo_join(chi_tracts, chi_tsa, "GEOID", "GEOID")
chi_tna_geo <- geo_join(chi_tracts, chi_tna, "GEOID", "GEOID")

# leaflet (interactive) version
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

# tmap (static) version
tmap_style("gray")
chi_tsa_map <- tm_shape(chi_tsa_geo) +
  tm_polygons("rate", title=paste0("Homicides and Non-Fatal Shootings per Capita ", minY, "-", maxY)) +
  tm_layout(legend.position=c("left", "bottom"))
save_tmap(chi_tsa_map, "figs/chi_tsa_map.png")

### NARCOTICS BY TRACT (ALL) ###

chi_tna_map <- tm_shape(chi_tna_geo) +
  tm_polygons("rate", title=paste0("Narcotics-Related Arrests per Capita ", minY, "-", maxY)) +
  tm_layout(legend.position=c("left", "bottom"))
save_tmap(chi_tna_map, "figs/chi_tna_map.png")

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
factpal <- colorFactor(brewer.pal(6, "Set1"), chi_clusters_geo$cluster)

chi_clusters_map <- leaflet() %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addPolygons(data = chi_clusters_geo, 
              color = ~factpal(cluster), # you need to use hex colors
              fillOpacity = 0.7, 
              weight = 1, 
              smoothFactor = 0.2,
              popup = popup)
chi_clusters_map

