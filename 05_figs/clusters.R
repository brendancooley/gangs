### SETUP ###

rm(list = ls())
source("../01_code/00_params.R")

libs <- c("tidyverse", "tigris", "tmap", "rgdal")
ipak(libs)

clusters <- read_csv(clusters_path, col_names=FALSE) %>% pull(.)
geoids_keep <- read_csv(geoids_keep_path, col_names=FALSE) %>% pull(.)
geoids_zero <- read_csv(geoids_zero_path, col_names=FALSE) %>% pull(.)
nc <- read_csv(nc_path, col_names=FALSE) %>% pull(.) # noise cluster
tracts <- readOGR(tracts_path)

### CLEAN ###

clusters_keep_df <- data.frame(clusters, geoids_keep)
colnames(clusters_keep_df) <- c("cluster", "GEOID")
zero_df <- data.frame(nc, geoids_zero)
colnames(zero_df) <- c("cluster", "GEOID")

clusters_df <- bind_rows(clusters_keep_df, zero_df) %>% as_tibble()
clusters_df$cluster <- as.factor(clusters_df$cluster)

# match representative districts
lk_id <- clusters_df %>% filter(GEOID==lk_geoid) %>% pull(cluster) %>% as.integer() - 1
gd_id <- clusters_df %>% filter(GEOID==gd_geoid) %>% pull(cluster) %>% as.integer() - 1
vl_id <- clusters_df %>% filter(GEOID==vl_geoid) %>% pull(cluster) %>% as.integer() - 1

known_ids <- c(lk_id, gd_id, vl_id, nc)
known_cols <- c(lk_col, gd_col, vl_col, nc_col)

# construct color mapping
col_mapping <- data.frame(known_ids, known_cols)
colnames(col_mapping) <- c("cluster", "color")

other_ids <- setdiff(clusters_df$cluster %>% unique(), known_ids) %>% as.integer()
other_cols <- rep(other_col, length(other_ids))
col_mapping_other <- data.frame(other_ids, other_cols)
colnames(col_mapping_other) <- c("cluster", "color")

col_mapping <- bind_rows(col_mapping, col_mapping_other)
col_mapping$cluster <- as.factor(col_mapping$cluster)

# merge and construct map
clusters_df_col <- left_join(clusters_df, col_mapping)
clusters_geo <- geo_join(tracts, clusters_df_col, "GEOID", "GEOID")

### FIGURE ###

chi_clusters_map <- tm_shape(clusters_geo) +
  tm_fill(col="color") +
  # tm_polygons("cluster", title=paste0("Cluster ID"), palette="Set3") +
  tm_layout(bg.color="#d0c7be", outer.bg.color="white", legend.position=c("left", "bottom"))
