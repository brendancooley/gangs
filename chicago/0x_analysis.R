### DON'T RUN THIS SECTION WHEN BUILDING PAPER ### 
wd <- getwd()
if ("chicago" %in% strsplit(wd, "/")[[1]]) {
  
  ### SETUP ###
  
  rm(list = ls())
  
  if (!'chicago' %in% strsplit(getwd(), "/")[[1]]) {
    setwd('chicago')
  }
  
  source("params.R")
  
  libs <- c("tidyverse", "tigris", "leaflet", "leaflet.extras", "tmap", "rgdal", "RColorBrewer", "reshape2", "lubridate", "patchwork", "ggnewscale")
  ipak(libs)
  
  ### DATA ###
  
  chi_clean <- read_csv(chi_clean_path)
  chi_tracts <- readOGR(chi_tracts_path)
  
  # group_paths <- list.dirs(chi_clust_fpath, recursive = FALSE)
  # group_paths <- group_paths[4]  # just all for now, comment out to run analysis for 5-year windows
  # id <- strsplit(i, "/")[[1]][3]
  
  # use produceResults in params to control what gets produced
  
  ### OUTPUT ### 
  
  nc <- read_csv(paste0(analysisSub, "/", nc_path), col_names=FALSE) %>% pull(.) # noise cluster
  
  clusters <- read_csv(paste0(analysisSub, "/", clusters_path), col_names=FALSE) %>% pull(.)
  geoid_keep <- read_csv(paste0(analysisSub, "/", geoid_keep_path), col_names=FALSE) %>% pull(.)
  geoid_zero <- read_csv(paste0(analysisSub, "/", geoid_zero_path), col_names=FALSE) %>% pull(.)
  J <- read_csv(paste0(analysisSub, "/", J_path), col_names=FALSE) %>% pull(.)
  K <- J - 1
  
  eigs <- read_csv(paste0(analysisSub, "/", eig_path), col_names=FALSE)
  
  P <- read_csv(paste0(analysisSub, "/", P_path), col_names=FALSE) %>% as.matrix()
  P_sorted <- read_csv(paste0(analysisSub, "/", P_sorted_path), col_names=FALSE) %>% as.matrix()
  
  Bhat <- read_csv(paste0(analysisSub, "/", Bhat_path), col_names=FALSE) %>% as.matrix()
  
}

minY <- min(chi_clean$year) %>% year()
maxY <- max(chi_clean$year) %>% year()

colnames(eigs) <- c("lbda")
eigs <- eigs %>% arrange(desc(lbda))
eigs$id <- seq(1, nrow(eigs))

colnames(P) <- seq(1, ncol(P))
colnames(P_sorted) <- seq(1, ncol(P_sorted))

clusters_keep_df <- data.frame(clusters, geoid_keep)
colnames(clusters_keep_df) <- c("cluster", "GEOID")
zero_df <- data.frame(nc, geoid_zero)
colnames(zero_df) <- c("cluster", "GEOID")

clusters_df <- bind_rows(clusters_keep_df, zero_df) %>% as_tibble()
clusters_df$cluster <- as.factor(clusters_df$cluster)

### SCREE PLOT ###

cut <- eigs %>% filter(id==J) %>% pull(lbda)
screePlot <- ggplot(eigs %>% filter(id <= screeN), aes(x=id, y=lbda)) +
  geom_point() +
  geom_hline(yintercept=cut, lty=2) +
  theme_classic() + 
  labs(title="Leading Eigenvalues of Covariance Matrix", subtitle="(Off-Diagonal Entries)", y="Eigenvalue") +
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank()) +
  theme(aspect.ratio=1)

### CLUSTERS ###

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
chi_clusters_geo <- geo_join(chi_tracts, clusters_df_col, "GEOID", "GEOID")

# tmap_options(bg.color = "#d0c7be")
chi_clusters_map <- tm_shape(chi_clusters_geo) +
  tm_fill(col="color") +
  # tm_polygons("cluster", title=paste0("Cluster ID"), palette="Set3") +
  tm_layout(bg.color="#d0c7be", outer.bg.color="white", legend.position=c("left", "bottom"))
# chi_clusters_map

# save_tmap(chi_clusters_map, "figs/maps/all.png")

### COV MATRICES ###
P_melted <- melt(P)
P_melted$value <- ifelse(P_melted$value < 0, 0, P_melted$value)
P_sorted_melted <- melt(P_sorted)
P_sorted_melted$value <- ifelse(P_sorted_melted$value < 0, 0, P_sorted_melted$value)

# summary(P_melted)
hmColors <- colorRampPalette(c("white", bcOrange))(10)

P_hm <- ggplot(data = P_melted, aes(x=Var1, y=Var2, fill=value)) + 
  geom_tile() +
  scale_fill_gradient(low=hmColors[1], high=hmColors[length(hmColors)]) +
  theme_classic() +
  coord_fixed()  +
  scale_y_continuous(trans = "reverse") +
  theme(legend.position = "none",
        axis.line=element_blank(),
        axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        axis.title.y=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank()) +
  labs(x=" ", y=" ", title="Covariance Matrix (Unsorted)", subtitle="(Diagonal Entries, Negative Entries = 0)") +
  annotate("rect", xmin=0, ymin=0, xmax=nrow(P), ymax=nrow(P), alpha=0, size=.5, color="black")

cluster_counts <- table(clusters_df$cluster)
end <- cluster_counts[length(cluster_counts)]
cluster_counts[rownames(cluster_counts) == as.character(nc)] <- end  # replace noise cluster with last cluster

# calculate effective noise cluster size (w/o zero vectors)
nc_size <- nrow(P) - sum(cluster_counts[-length(cluster_counts)])
cluster_counts[length(cluster_counts)] <- nc_size

P_hm_sorted <- ggplot(data = P_sorted_melted, aes(x=Var1, y=Var2, fill=value)) + 
  geom_tile() +
  scale_fill_gradient(low=hmColors[1], high=hmColors[length(hmColors)]) +
  theme_classic() +
  coord_fixed() +
  scale_y_continuous(trans = "reverse") +
  theme(legend.position = "none",
        axis.line=element_blank(),
        axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        axis.title.y=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank()) +
  labs(x=" ", y=" ", title="Covariance Matrix (Sorted)", subtitle="(Diagonal Entries, Negative Entries = 0)") +
  annotate("rect", xmin=0, ymin=0, xmax=nrow(P), ymax=nrow(P), alpha=0, size=.5, color="black")

coord <- 0
for (j in cluster_counts) {
  P_hm_sorted <- P_hm_sorted +
    annotate("rect", xmin=coord, ymin=coord, xmax=coord+j, ymax=coord+j, alpha=0, size=.5, color="black")
  coord <- coord + j
}
block_hm <- P_hm + P_hm_sorted

### BHAT ###
Bhat_melted <- melt(Bhat)
nrow(Bhat_melted)
Bhat_melted$g1 <- rep(seq(0, J-1), J)
Bhat_melted$g2 <- rep(seq(0, J-1), rep(J, J))
Bhat_melted <- as_tibble(Bhat_melted)
Bhat_melted <- Bhat_melted %>% select(-Var1, -Var2)

col_mapping$cluster <- as.integer(col_mapping$cluster) - 1
Bhat_melted <- left_join(Bhat_melted, col_mapping, by=c("g1"="cluster"))
colnames(Bhat_melted)[colnames(Bhat_melted)=="color"] <- "color1"
Bhat_melted <- left_join(Bhat_melted, col_mapping, by=c("g2"="cluster"))
colnames(Bhat_melted)[colnames(Bhat_melted)=="color"] <- "color2"

# flop noise cluster
Bhat_melted$g1 <- ifelse(Bhat_melted$g1==nc, K+1, Bhat_melted$g1)
Bhat_melted$g1 <- ifelse(Bhat_melted$g1==K, nc, Bhat_melted$g1)
Bhat_melted$g1 <- ifelse(Bhat_melted$g1==K+1, K, Bhat_melted$g1)

Bhat_melted$g2 <- ifelse(Bhat_melted$g2==nc, K+1, Bhat_melted$g2)
Bhat_melted$g2 <- ifelse(Bhat_melted$g2==K, nc, Bhat_melted$g2)
Bhat_melted$g2 <- ifelse(Bhat_melted$g2==K+1, K, Bhat_melted$g2)

col_mapping$cluster <- ifelse(col_mapping$cluster==nc, K+1, col_mapping$cluster)
col_mapping$cluster <- ifelse(col_mapping$cluster==K, nc, col_mapping$cluster)
col_mapping$cluster <- ifelse(col_mapping$cluster==K+1, K, col_mapping$cluster)
col_mapping <- col_mapping %>% as_tibble() %>% arrange(desc(cluster))

# drop noise cluster
Bhat_melted <- Bhat_melted %>% filter(g1!=K & g2!=K)

Bhat_melted_diag <- Bhat_melted %>% filter(Bhat_melted$g1==Bhat_melted$g2)
Bhat_melted_diag <- Bhat_melted_diag %>% arrange(desc(g1))

bhatColors <- colorRampPalette(c("white", "#696969"))(10)

Bhat_hm <- ggplot(data = Bhat_melted, aes(x=g1, y=g2, fill=value)) + 
  geom_tile(colour="white", width=.9, height=.9) +
  scale_fill_gradient(low=hmColors[1], high=bhatColors[length(bhatColors)]) +
  new_scale_fill() +
  geom_tile(data=Bhat_melted_diag, aes(fill=forcats::fct_inorder(Bhat_melted_diag$color1)), colour="white", width=.9, height=.9) +
  scale_fill_manual(values=Bhat_melted_diag$color1) +
  theme_classic() +
  coord_fixed() +
  scale_y_continuous(trans = "reverse") +
  theme(legend.position = "none",
        axis.line=element_blank(),
        axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        axis.title.y=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank()) +
  labs(x=" ", y=" ", title="Inter-Gang Conflict Intensities")



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
