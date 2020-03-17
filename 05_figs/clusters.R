### SETUP ###

# rm(list = ls())
# invisible(lapply(paste0('package:', names(sessionInfo()$otherPkgs)), detach, character.only=TRUE, unload=TRUE))
source("../01_code/00_params.R")

libs <- c("tidyverse", "tigris", "tmap", "rgdal", "GISTools", "scales", "leaflet")
ipak(libs)

### BASE ###

clusters <- read_csv(clusters_path, col_names=FALSE) %>% pull(.)
clusters <- clusters + 1
geoids_keep <- read_csv(geoids_keep_path, col_names=FALSE) %>% pull(.)
geoids_zero <- read_csv(geoids_zero_path, col_names=FALSE) %>% pull(.)

nc <- read_csv(nc_path, col_names=FALSE) %>% pull(.) # noise cluster
nc <- nc + 1

clusters_base <- data.frame(clusters, geoids_keep)
colnames(clusters_base) <- c("cluster", "GEOID")
zeros_base <- data.frame(nc, geoids_zero)
colnames(zeros_base) <- c("cluster", "GEOID")

clusters_base <- bind_rows(clusters_base, zeros_base) %>% as_tibble()
clusters_base <- clusters_base %>% arrange(desc(GEOID))
clusters_base$cluster <- as.factor(clusters_base$cluster)

clusters_base_geo <- geo_join(tracts, clusters_base, "GEOID", "GEOID")

clusters_base_map <- tm_shape(clusters_base_geo) +
  tm_fill("cluster") +
  # tm_text("GEOID", size=.25) +
  tm_borders(col="white") +
  tm_shape(chi_outline) +
  tm_borders(col="black") +
  # tm_polygons("cluster", title=paste0("Cluster ID"), palette="Set3") +
  tm_layout(bg.color="white", outer.bg.color="white", legend.position=c("left", "bottom"))

leaflet() %>% addPolygons(data=tracts, popup=~GEOID)

### ALL BOOTSTRAPS AND CPD MAPS ###

turf_shares <- read_csv(turf_shares_path)
turf_binary <- read_csv(turf_binary_path)

tracts <- readOGR(tracts_path, verbose=FALSE)

# cluster props
cluster_props <- read_csv(cluster_props_path)

# cluster_binary
cluster_binary <- read_csv(cluster_binary_path)

# find max cluster_prop
cp_mat <- cluster_props %>% dplyr::select(-c("GEOID", as.character(nc))) %>% as.matrix()
cluster_props$max_id <- apply(cp_mat, 1, which.max)
cluster_props$alpha <- apply(cp_mat, 1, max) 

# aggregate smaller gangs (cpd)
major_gangs <- colnames(turf_shares)[2:5]

turf_shares_other <- turf_shares %>% dplyr::select(-one_of(major_gangs),-GEOID) %>% rowSums()
turf_shares_reduced <- turf_shares %>% dplyr::select(GEOID, one_of(major_gangs))
turf_shares_reduced$other <- turf_shares_other
reduced_gangs <- c(major_gangs, "other")
# turf_shares_null <- 1 - turf_shares_reduced %>% dplyr::select(one_of(reduced_gangs)) %>% rowSums()
# turf_shares_reduced$nc <- turf_shares_null
# reduced_gangs <- c(reduced_gangs, "nc")

turf_binary$owner <- ifelse(turf_binary$owner %in% c(major_gangs, "peaceful"), turf_binary$owner, "other")

ts_mat <- turf_shares_reduced %>% dplyr::select(one_of(reduced_gangs)) %>% as.matrix()
owner <- reduced_gangs[apply(ts_mat, 1, which.max)]
turf_shares_reduced$owner <- owner
turf_shares_reduced$alpha <- apply(ts_mat, 1, max) 
turf_shares_reduced$alpha <- ifelse(turf_shares_reduced$alpha >= 1, .99, turf_shares_reduced$alpha)

### CLEAN ###

# match representative districts
lk_id <- cluster_props %>% filter(GEOID==lk_geoid) %>% pull(max_id) %>% as.integer()
gd_id <- cluster_props %>% filter(GEOID==gd_geoid) %>% pull(max_id) %>% as.integer()
vl_id <- cluster_props %>% filter(GEOID==vl_geoid) %>% pull(max_id) %>% as.integer()
bps_id <- cluster_props %>% filter(GEOID==bps_geoid) %>% pull(max_id) %>% as.integer()

# construct color mappings
known_ids <- c(lk_id, gd_id, vl_id)
known_cols <- c(lk_col, gd_col, vl_col)
col_mapping <- data.frame(known_ids, known_cols)
colnames(col_mapping) <- c("max_id", "color")
# show_col(col_mapping$color %>% as.character(), labels=FALSE)

turf_cols <- c(gd_col, bps_col, lk_col, vl_col, other_col)
col_mapping_turf <- data.frame(reduced_gangs, turf_cols)
colnames(col_mapping_turf) <- c("owner", "color")
col_mapping_turf$owner <- as.character(col_mapping_turf$owner)
# show_col(col_mapping_turf$color %>% as.character())

# merge and construct map
cluster_props_df_col <- left_join(cluster_props, col_mapping)
cluster_props_df_col$color_a <- add.alpha(cluster_props_df_col$color, cluster_props_df_col$alpha)
cluster_props_geo <- geo_join(tracts, cluster_props_df_col, "GEOID", "GEOID")
# show_col(clusters_df_col$color, labels=FALSE)
# show_col(clusters_df_col$color_a, labels=FALSE)

cluster_binary <- cluster_binary %>% filter(cluster!=nc)
cluster_binary$cluster <- ifelse(cluster_binary$cluster > nc, cluster_binary$cluster-1, cluster_binary$cluster)

cluster_binary_df_col <- left_join(cluster_binary, col_mapping, by=c("cluster"="max_id"))
cluster_binary_df_col$color <- cluster_binary_df_col$color %>% as.character()
cluster_binary_geo <- geo_join(tracts, cluster_binary_df_col, "GEOID", "GEOID")

turf_shares_reduced_col <- left_join(turf_shares_reduced, col_mapping_turf)
turf_shares_reduced_col$color_a <- add.alpha(turf_shares_reduced_col$color, turf_shares_reduced_col$alpha)
turf_shares_geo <- geo_join(tracts, turf_shares_reduced_col, "GEOID", "GEOID")
# show_col(turf_shares_reduced_col$color %>% as.character(), labels=FALSE)
# show_col(turf_shares_reduced_col$color_a, labels=FALSE)

turf_binary_col <- left_join(turf_binary, col_mapping_turf)
turf_binary_col$color <- turf_binary_col$color %>% as.character()
turf_binary_col$color <- ifelse(is.na(turf_binary_col$color), "#ffffff", turf_binary_col$color)
turf_binary_geo <- geo_join(tracts, turf_binary_col, "GEOID", "GEOID")

### FIGURE ###

chi_outline <- gUnaryUnion(tracts)

cluster_props_map <- tm_shape(cluster_props_geo) +
  tm_fill(col="color_a") +
  tm_borders(col="white") +
  tm_shape(chi_outline) +
  tm_borders(col="black") +
  # tm_polygons("cluster", title=paste0("Cluster ID"), palette="Set3") +
  tm_layout(bg.color="white", outer.bg.color="white", legend.position=c("left", "bottom"))

cluster_binary_map <- tm_shape(cluster_binary_geo) +
  tm_fill(col="color") +
  tm_borders(col="white") +
  tm_shape(chi_outline) +
  tm_borders(col="black") +
  # tm_polygons("cluster", title=paste0("Cluster ID"), palette="Set3") +
  tm_layout(bg.color="white", outer.bg.color="white", legend.position=c("left", "bottom"))

chi_turf_map <- tm_shape(turf_shares_geo) +
  tm_fill(col="color_a") +
  tm_borders(col="white") +
  tm_shape(chi_outline) +
  tm_borders(col="black") +
  tm_layout(bg.color="white", outer.bg.color="white", legend.position=c("left", "bottom"))

chi_turf_binary_map <- tm_shape(turf_binary_geo) +
  tm_fill(col="color") +
  tm_borders(col="white") +
  tm_shape(chi_outline) +
  tm_borders(col="black") +
  tm_layout(bg.color="white", outer.bg.color="white", legend.position=c("left", "bottom"))
