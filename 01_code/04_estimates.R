### SETUP ###

rm(list = ls())
source("00_params.R")
source("helpers.R")

libs <- c("tidyverse", "combinat")
ipak(libs)

### DATA ###

J <- read_csv(J_path, col_names=FALSE) %>% pull(.)
K <- J - 1

clusters_base <- read_csv(clusters_path, col_names=FALSE) %>% pull(.)
nc_base <- read_csv(nc_path, col_names=FALSE) %>% pull(.) # noise cluster
geoids_keep_base <- read_csv(geoids_keep_path, col_names=FALSE) %>% pull(.)
geoids_zero_base <- read_csv(geoids_zero_path, col_names=FALSE) %>% pull(.)

Bhat_base <- read_csv(Bhat_path, col_names=FALSE)

### CLEAN ###

clusters_base_keep_df <- data.frame(clusters_base, geoids_keep_base)
colnames(clusters_base_keep_df) <- c("cluster", "GEOID")
zero_base_df <- data.frame(nc_base, geoids_zero_base)
colnames(zero_base_df) <- c("cluster", "GEOID")

clusters_base_df <- bind_rows(clusters_base_keep_df, zero_base_df) %>% as_tibble()
clusters_base_df <- clusters_base_df %>% arrange(desc(GEOID))
clusters_base_df$cluster <- clusters_base_df$cluster + 1
nc_base <- nc_base + 1

### GATHER BOOTSTRAP ESTIMATES ###

clustersM <- matrix(nrow=nrow(clusters_base_df), ncol=L)
BhatL <- list()

for (i in 1:L) {
  
  clusters_i <- read_csv(paste0(clusters_bs_path, i, ".csv"), col_names=FALSE) %>% pull(.)
  nc_i <- read_csv(paste0(nc_bs_path, i, ".csv"), col_names=FALSE) %>% pull(.)
  geoids_keep_i <- read_csv(paste0(geoids_keep_bs_path, i, ".csv"), col_names=FALSE) %>% pull(.)
  geoids_zero_i <- read_csv(paste0(geoids_zero_bs_path, i, ".csv"), col_names=FALSE) %>% pull(.)
  
  Bhat_i <- read_csv(paste0(Bhat_bs_path, i, ".csv"), col_names=FALSE) %>% as.matrix()
  
  clusters_i_keep_df <- data.frame(clusters_i, geoids_keep_i)
  colnames(clusters_i_keep_df) <- c("cluster", "GEOID")
  zero_i_df <- data.frame(nc_i, geoids_zero_i)
  colnames(zero_i_df) <- c("cluster", "GEOID")
  
  clusters_i_df <- bind_rows(clusters_i_keep_df, zero_i_df) %>% as_tibble()
  clusters_i_df <- clusters_i_df %>% arrange(desc(GEOID))
  clusters_i_df$cluster <- clusters_i_df$cluster + 1
  
  pc_out <- permute_clusters(clusters_i_df$cluster, clusters_base_df$cluster)
  clusters_i_df$cluster <- pc_out["clusters"][[1]]

  clustersM[,i] <- clusters_i_df$cluster
  
  labels <- pc_out["labels"][[1]]
  
  Bhat_i <- Bhat_i[labels, labels]
  
  BhatL[[i]] <- Bhat_i
  
}

cluster_props <- apply(clustersM, 1, function(x) table(factor(x, levels=seq(1,J))) / L)
cluster_props <- t(cluster_props) %>% as_tibble()
cluster_props$GEOID <- clusters_base_df$GEOID
cluster_props <- cluster_props %>% select(GEOID, everything())
# cluster_props %>% print(n=1000)

write_csv(cluster_props, cluster_props_path)

Bhat_mean <- Reduce("+", BhatL) / length(BhatL)

write_csv(Bhat_mean %>% as.data.frame(), Bhat_mean_path, col_names=FALSE)
