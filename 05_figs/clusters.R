### SETUP ###

rm(list = ls())
source("../01_code/00_params.R")

libs <- c("tidyverse", "tigris", "tmap", "rgdal", "GISTools")
ipak(libs)

# base
clusters <- read_csv(clusters_path, col_names=FALSE) %>% pull(.)
geoids_keep <- read_csv(geoids_keep_path, col_names=FALSE) %>% pull(.)
geoids_zero <- read_csv(geoids_zero_path, col_names=FALSE) %>% pull(.)
nc <- read_csv(nc_path, col_names=FALSE) %>% pull(.) # noise cluster
nc <- nc + 1

tracts <- readOGR(tracts_path)

# props
cluster_props <- read_csv(cluster_props_path)
cp_mat <- cluster_props %>% dplyr::select(-c("GEOID", as.character(nc))) %>% as.matrix()
cluster_props$max_id <- apply(cp_mat, 1, which.max)
cluster_props$alpha <- apply(cp_mat, 1, max) 
table(cluster_props$max_id)

### CLEAN ###

# match representative districts
lk_id <- cluster_props %>% filter(GEOID==lk_geoid) %>% pull(max_id) %>% as.integer()
gd_id <- cluster_props %>% filter(GEOID==gd_geoid) %>% pull(max_id) %>% as.integer()
vl_id <- cluster_props %>% filter(GEOID==vl_geoid) %>% pull(max_id) %>% as.integer()

known_ids <- c(lk_id, gd_id, vl_id)
known_cols <- c(lk_col, gd_col, vl_col)

# construct color mapping
col_mapping <- data.frame(known_ids, known_cols)
colnames(col_mapping) <- c("max_id", "color")

# merge and construct map
clusters_df_col <- left_join(cluster_props, col_mapping)
clusters_df_col$color_a <- add.alpha(clusters_df_col$color, clusters_df_col$alpha)
clusters_geo <- geo_join(tracts, clusters_df_col, "GEOID", "GEOID")

### FIGURE ###

chi_clusters_map <- tm_shape(clusters_geo) +
  tm_fill(col="color_a") +
  tm_polygons(tracts) +
  # tm_polygons("cluster", title=paste0("Cluster ID"), palette="Set3") +
  tm_layout(bg.color="white", outer.bg.color="white", legend.position=c("left", "bottom"))
