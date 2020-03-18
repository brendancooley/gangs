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

cpd_turf_binary <- read_csv(turf_binary_path) %>% arrange(GEOID)
cpd_ownership_mean <- read_csv(turf_shares_path)

gangs_major <- read_csv(paste0(gang_territory_path, "major_gangs.csv"), col_names=FALSE) %>% pull(.)
# cpd_gangs <- cpd_turf_binary$owner %>% unique()
# cpd_gangs <- data.frame(cpd_gangs, seq(1, length(cpd_gangs)))
# colnames(cpd_gangs) <- c("gang_name", "gang_id")

# gangs_major <- colnames(cpd_ownership_mean[2:8])  # 7 about as large as we can go for calculating label permutations
# permutations <- do.call(cbind, permn(unique(gangs_major)))

cpd_turf_binary$owner <- as.character(cpd_turf_binary$owner)
cpd_turf_gangs_all <- cpd_turf_binary %>% filter(owner!="peaceful")
# cpd_turf_binary$owner <- ifelse(cpd_turf_binary$owner %in% c(gangs_major, "peaceful"), cpd_turf_binary$owner, "other")

owners_all <- cpd_turf_binary %>% pull(owner) %>% unique()
# labels <- data.frame(owners_all, seq(1, length(owners_all)))
# colnames(labels) <- c("owner", "gang_id")

### CLEAN ###

clusters_base_keep_df <- data.frame(clusters_base, geoids_keep_base)
colnames(clusters_base_keep_df) <- c("cluster", "GEOID")
zero_base_df <- data.frame(nc_base, geoids_zero_base)
colnames(zero_base_df) <- c("cluster", "GEOID")

clusters_base_df <- bind_rows(clusters_base_keep_df, zero_base_df) %>% as_tibble()
clusters_base_df <- clusters_base_df %>% arrange(desc(GEOID))
clusters_base_df$cluster <- clusters_base_df$cluster + 1
nc_base <- nc_base + 1
clusters_base_df <- clusters_base_df %>% arrange(GEOID)

### GATHER BOOTSTRAP ESTIMATES ###

L <- 90
clustersM <- matrix(nrow=nrow(clusters_base_df), ncol=L)
BhatL <- list()

for (i in 1:L) {
  
  # blank matrix for Bhat vals
  Bhat_mat <- matrix(nrow=gangs_V+1, ncol=gangs_V+1)
  colnames(Bhat_mat) <- rownames(Bhat_mat) <- owners_all
  
  clusters_i <- read_csv(paste0(clusters_bs_path, i, ".csv"), col_names=FALSE, col_types=cols()) %>% pull(.)
  nc_i <- read_csv(paste0(nc_bs_path, i, ".csv"), col_names=FALSE, col_types=cols()) %>% pull(.)
  geoids_keep_i <- read_csv(paste0(geoids_keep_bs_path, i, ".csv"), col_names=FALSE, col_types=cols()) %>% pull(.)
  geoids_zero_i <- read_csv(paste0(geoids_zero_bs_path, i, ".csv"), col_names=FALSE, col_types=cols()) %>% pull(.)
  
  J_i <- read_csv(paste0(J_bs_path, i, ".csv"), col_names=FALSE, col_types=cols()) %>% pull(.)
  
  Bhat_i <- read_csv(paste0(Bhat_bs_path, i, ".csv"), col_names=FALSE, col_types=cols()) %>% as.matrix()
  
  clusters_i_keep_df <- data.frame(clusters_i, geoids_keep_i)
  colnames(clusters_i_keep_df) <- c("cluster", "GEOID")
  zero_i_df <- data.frame(nc_i, geoids_zero_i)
  colnames(zero_i_df) <- c("cluster", "GEOID")
  
  clusters_i_df <- bind_rows(clusters_i_keep_df, zero_i_df) %>% as_tibble()
  clusters_i_df <- clusters_i_df %>% arrange(GEOID)
  clusters_i_df$cluster <- clusters_i_df$cluster + 1
  nc_i <- nc_i + 1
  
  permn_results <- permute_clusters(clusters_i_df$cluster, cpd_turf_binary$owner)
  # print(permn_results[[1]] %>% unique())
  clusters_i_df$assignment <- permn_results[[1]]
  print(table(clusters_i_df$assignment))
  
  # pc_out <- permute_clusters(clusters_i_df$cluster, clusters_base_df$cluster)
  # clusters_i_df$cluster <- pc_out["clusters"][[1]]
  # clustersM[,i] <- clusters_i_df$cluster
  labels <- permn_results["labels"][[1]]
  loss_frac_all <- permn_results[["loss"]] / nrow(clusters_i_df)
  print("loss all:")
  print(loss_frac_all)
  
  clusters_gangs_all_i <- clusters_i_df %>% filter(GEOID %in% cpd_turf_gangs_all$GEOID)
  loss_frac_gangs_all <- sum(clusters_gangs_all_i$assignment != cpd_turf_gangs_all$owner) / nrow(cpd_turf_gangs_all) 
  print("loss gangs:")
  print(loss_frac_gangs_all)
  
  clusters_gangs_i <- clusters_i_df %>% filter(assignment!="peaceful")
  gangs_i <- clusters_gangs_i$assignment %>% unique()
  cpd_gangs_i <- cpd_turf_binary %>% filter(GEOID %in% clusters_gangs_i$GEOID)
  loss_frac_gangs_i <- sum(clusters_gangs_i$assignment != cpd_gangs_i$owner) / nrow(clusters_gangs_i)
  print("loss gangs i:")
  print(loss_frac_gangs_i)
  
  clustersM[,i] <- clusters_i_df$assignment
  
  for (j in 1:length(labels)) {
    for (k in 1:length(labels)) {
      id_j <- labels[j]
      id_k <- labels[k]
      if (j <= J_i & k <= J_i) {
        Bhat_mat[id_j, id_k] <- Bhat_i[j, k]
      } else {
        Bhat_mat[id_j, id_k] <- NA
      }
    }
  }
  
  # Bhat_i <- Bhat_i[labels, labels]
  
  BhatL[[i]] <- Bhat_i
  
}

# table(clustersM)

cluster_props <- apply(clustersM, 1, function(x) table(factor(x, levels=owners_all))/L)
cluster_props <- t(cluster_props) %>% as_tibble()
cluster_props$GEOID <- clusters_base_df$GEOID
cluster_props <- cluster_props %>% select(GEOID, everything())
# cluster_props %>% print(n=1000)

write_csv(cluster_props, cluster_props_path)

### CONVERT TO BINARY OWNERSHIP MATRIX ###

cluster_props %>% pivot_longer(owners_all, names_to="gang")

owner <- cluster_props %>% select(-GEOID, -peaceful) %>% apply(1, function(x) which.max(x))
owner_prop <- cluster_props %>% select(-GEOID, -peaceful) %>% apply(1, function(x) max(x))
cluster_binary <- data.frame(cluster_props$GEOID, colnames(cluster_props %>% select(-GEOID, -peaceful))[owner], owner_prop) %>% as_tibble()
colnames(cluster_binary) <- c("GEOID", "owner", "owner_prop")
cluster_binary$owner
cluster_binary$owner <- cluster_binary$owner %>% as.character()
cluster_binary$owner <- ifelse(cluster_binary$owner_prop < .05, "peaceful", cluster_binary$owner)
table(cluster_binary$owner)

cluster_binary <- cluster_binary %>% select(-owner_prop)
write_csv(cluster_binary, cluster_binary_path)

print("hello")

### B_HAT ###

# Bhat_mean <- Reduce("+", BhatL) / length(BhatL)

# write_csv(Bhat_mean %>% as.data.frame(), Bhat_mean_path, col_names=FALSE)





### LOSS BASELINE ###

for (i in 1:100) {
  print(sum(sample(cpd_turf_binary$owner, replace=F) != cpd_turf_binary$owner) / nrow(clusters_i_df))
  print(sum(sample(cpd_turf_gangs_all$owner, replace=F) != cpd_turf_gangs_all$owner) / nrow(cpd_turf_gangs_all))
}

# two more metrics
  # 2) gangs overall
  # 3) among gangs we match to