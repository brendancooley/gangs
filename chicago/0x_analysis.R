### SETUP ###

rm(list = ls())

if (!'chicago' %in% strsplit(getwd(), "/")[[1]]) {
  setwd('chicago')
}

source("params.R")

libs <- c("tidyverse", "tigris", "leaflet", "leaflet.extras", "tmap", "rgdal", "RColorBrewer", "reshape2", "lubridate")
ipak(libs)

### DATA ###

chi_clean <- read_csv(chi_clean_path)
minY <- min(chi_clean$year) %>% year()
maxY <- max(chi_clean$year) %>% year()

chi_tracts <- readOGR(chi_tracts_path)

group_paths <- list.dirs(chi_clust_fpath, recursive = FALSE)

### OUTPUT ### 

for (i in group_paths) {
  
  id <- strsplit(i, "/")[[1]][3]
  
  nc <- read_csv(paste0(i, "/", nc_path), col_names=FALSE) %>% pull(.) # noise cluster
  
  clusters <- read_csv(paste0(i, "/", clusters_path), col_names=FALSE) %>% pull(.)
  geoid_keep <- read_csv(paste0(i, "/", geoid_keep_path), col_names=FALSE) %>% pull(.)
  geoid_zero <- read_csv(paste0(i, "/", geoid_zero_path), col_names=FALSE) %>% pull(.)
  
  P <- read_csv(paste0(i, "/", P_path), col_names=FALSE) %>% as.matrix()
  P_sorted <- read_csv(paste0(i, "/", P_sorted_path), col_names=FALSE) %>% as.matrix()
  colnames(P) <- seq(1, ncol(P))
  colnames(P_sorted) <- seq(1, ncol(P_sorted))
  
  clusters_keep_df <- data.frame(clusters, geoid_keep)
  colnames(clusters_keep_df) <- c("cluster", "GEOID")
  zero_df <- data.frame(nc, geoid_zero)
  colnames(zero_df) <- c("cluster", "GEOID")
  
  clusters_df <- bind_rows(clusters_keep_df, zero_df) %>% as_tibble()
  clusters_df$cluster <- as.factor(clusters_df$cluster)
  
  ### CLUSTERS ###
  
  chi_clusters_geo <- geo_join(chi_tracts, clusters_df, "GEOID", "GEOID")
  
  tmap_style("white")
  chi_clusters_map <- tm_shape(chi_clusters_geo) +
    tm_polygons("cluster", title=paste0("Cluster ID"), palette="Set3") +
    tm_layout(legend.position=c("left", "bottom"))
  chi_clusters_map
  
  save_tmap(chi_clusters_map, paste0("figs/maps/", id, ".png"))
  
  ### COV MATRICES ###
  P_melted <- melt(P)
  P_sorted_melted <- melt(P_sorted)
  
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
    labs(x=" ", y=" ", title="Covariance Matrix (Unsorted)")
  
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
    labs(x=" ", y=" ", title="Covariance Matrix (Sorted)")
  
  coord <- 0
  for (j in cluster_counts) {
    P_hm_sorted <- P_hm_sorted +
      annotate("rect", xmin=coord, ymin=coord, xmax=coord+j, ymax=coord+j, alpha=0, size=.5, color="black")
    coord <- coord + j
  }
  
}





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
