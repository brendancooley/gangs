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
# cpd_turf_gangs_all$owner %>% unique()
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

clustersM <- matrix(nrow=nrow(clusters_base_df), ncol=L)
BhatL <- list()
cpd_agreement_ratio_vec <- c()
cpd_agreement_ratio_gang_vec <- c()
cpd_agreement_ratio_peaceful_vec <- c()
gang_frac_vec <- c()
J_estimates_vec <- c()
label_counts <- data.frame(owners_all, 0) %>% as_tibble()
colnames(label_counts) <- c("owner", "count")

for (i in 1:L) {
  
  # blank matrix for Bhat vals
  Bhat_mat <- matrix(nrow=length(owners_all), ncol=length(owners_all))
  colnames(Bhat_mat) <- rownames(Bhat_mat) <- owners_all
  
  clusters_i <- read_csv(paste0(clusters_bs_path, i, ".csv"), col_names=FALSE, col_types=cols()) %>% pull(.)
  nc_i <- read_csv(paste0(nc_bs_path, i, ".csv"), col_names=FALSE, col_types=cols()) %>% pull(.)
  geoids_keep_i <- read_csv(paste0(geoids_keep_bs_path, i, ".csv"), col_names=FALSE, col_types=cols()) %>% pull(.)
  geoids_zero_i <- read_csv(paste0(geoids_zero_bs_path, i, ".csv"), col_names=FALSE, col_types=cols()) %>% pull(.)
  
  J_i <- read_csv(paste0(J_bs_path, i, ".csv"), col_names=FALSE, col_types=cols()) %>% pull(.)
  J_estimates_vec <- c(J_estimates_vec, J_i)
  
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
  
  labels_in <- permn_results[[1]] %>% unique()
  for (j in labels_in) {
    label_counts$count[label_counts$owner==j] <- label_counts$count[label_counts$owner==j] + 1
  }
  
  clusters_i_df$assignment <- permn_results[[1]]
  print(table(clusters_i_df$assignment))
  
  # pc_out <- permute_clusters(clusters_i_df$cluster, clusters_base_df$cluster)
  # clusters_i_df$cluster <- pc_out["clusters"][[1]]
  # clustersM[,i] <- clusters_i_df$cluster
  labels <- permn_results["labels"][[1]]
  cpd_agreement_ratio_i <- 1 - permn_results[["loss"]] / nrow(clusters_i_df)
  cpd_agreement_ratio_vec <- c(cpd_agreement_ratio_vec, cpd_agreement_ratio_i)
  
  clusters_i_df_gang <- clusters_i_df %>% filter(assignment != "peaceful") 
  clusters_i_df_peaceful <- clusters_i_df %>% filter(assignment == "peaceful")
  cpd_turf_gang_i <- cpd_turf_binary %>% filter(GEOID %in% clusters_i_df_gang$GEOID)
  cpd_turf_peaceful_i <- cpd_turf_binary %>% filter(GEOID %in% clusters_i_df_peaceful$GEOID)
  cpd_agreement_ratio_gang_i <- sum(clusters_i_df_gang$assignment == cpd_turf_gang_i$owner) / nrow(clusters_i_df_gang)
  cpd_agreement_ratio_peaceful_i <- sum(clusters_i_df_peaceful$assignment == cpd_turf_peaceful_i$owner) / nrow(clusters_i_df_peaceful)
  cpd_agreement_ratio_gang_vec <- c(cpd_agreement_ratio_gang_vec, cpd_agreement_ratio_gang_i)
  cpd_agreement_ratio_peaceful_vec <- c(cpd_agreement_ratio_peaceful_vec, cpd_agreement_ratio_peaceful_i)
  
  gang_frac_i <- nrow(clusters_i_df_gang) / nrow(clusters_i_df)
  gang_frac_vec <- c(gang_frac_vec, gang_frac_i)
  
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
  
  BhatL[[i]] <- Bhat_mat
  
}

# J
write_csv(J_estimates_vec %>% as.data.frame(), J_all_path, col_names=FALSE)
# J_estimates_vec <- J_estimates_vec %>% sort()

# label counts
write_csv(label_counts, label_counts_path)

# gang frac
write_csv(gang_frac_vec %>% as.data.frame(), gang_frac_path, col_names=FALSE)

# cpd agreement
write_csv(cpd_agreement_ratio_vec %>% as.data.frame(), cpd_agreement_ratio_path, col_names=FALSE)
write_csv(cpd_agreement_ratio_peaceful_vec %>% as.data.frame(), cpd_agreement_ratio_peaceful_path, col_names=FALSE)
write_csv(cpd_agreement_ratio_gang_vec %>% as.data.frame(), cpd_agreement_ratio_gang_path, col_names=FALSE)
# cpd_agreement_ratio <- read_csv(cpd_agreement_ratio_path, col_names=FALSE) %>% pull()
# quantile(cpd_agreement_ratio, c(.025, .975))


cluster_props <- apply(clustersM, 1, function(x) table(factor(x, levels=owners_all))/L)
cluster_props <- t(cluster_props) %>% as_tibble()
cluster_props$GEOID <- clusters_base_df$GEOID
cluster_props <- cluster_props %>% select(GEOID, everything())
# cluster_props %>% print(n=1000)

write_csv(cluster_props, cluster_props_path)

### SUBSET TO ITERATIONS WITH K=4 ###

L4 <- sum(J_estimates_vec==5)
clustersM4 <- matrix(nrow=nrow(clusters_base_df), ncol=L4)
ids4 <- which(J_estimates_vec==5)

for (idx in 1:length(ids4)) {
  
  i <- ids4[idx]
  
  clusters_i <- read_csv(paste0(clusters_bs_path, i, ".csv"), col_names=FALSE, col_types=cols()) %>% pull(.)
  geoids_keep_i <- read_csv(paste0(geoids_keep_bs_path, i, ".csv"), col_names=FALSE, col_types=cols()) %>% pull(.)
  geoids_zero_i <- read_csv(paste0(geoids_zero_bs_path, i, ".csv"), col_names=FALSE, col_types=cols()) %>% pull(.)
  
  clusters_i_keep_df <- data.frame(clusters_i, geoids_keep_i)
  colnames(clusters_i_keep_df) <- c("cluster", "GEOID")
  zero_i_df <- data.frame(nc_i, geoids_zero_i)
  colnames(zero_i_df) <- c("cluster", "GEOID")
  
  clusters_i_df <- bind_rows(clusters_i_keep_df, zero_i_df) %>% as_tibble()
  clusters_i_df <- clusters_i_df %>% arrange(GEOID)
  clusters_i_df$cluster <- clusters_i_df$cluster + 1
  
  permn_results <- permute_clusters(clusters_i_df$cluster, cpd_turf_binary$owner)
  
  clusters_i_df$assignment <- permn_results[[1]]
  clustersM4[,idx] <- clusters_i_df$assignment
  
}

# export
cluster_props4 <- apply(clustersM4, 1, function(x) table(factor(x, levels=owners_all))/L4)
cluster_props4 <- t(cluster_props4) %>% as_tibble()
cluster_props4$GEOID <- clusters_base_df$GEOID
cluster_props4 <- cluster_props4 %>% select(GEOID, everything())
# cluster_props %>% print(n=1000)

write_csv(cluster_props4, cluster_props4_path)

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

### B_HAT ###

Bhat_mean <- apply(simplify2array(BhatL), 1:2, mean, na.rm=T)
Bhat_lb <- apply(simplify2array(BhatL), 1:2, quantile, na.rm=T, probs=.025)
Bhat_ub <- apply(simplify2array(BhatL), 1:2, quantile, na.rm=T, probs=.975)

write_csv(Bhat_mean %>% as.data.frame(), Bhat_mean_path)
write_csv(Bhat_lb %>% as.data.frame(), Bhat_lb_path)
write_csv(Bhat_ub %>% as.data.frame(), Bhat_ub_path)


### LOSS BASELINE ###

for (i in 1:10000) {
  sample_agreement <- sum(sample(cpd_turf_binary$owner, replace=F) == cpd_turf_binary$owner) / nrow(clusters_i_df)
  # print(sum(sample(cpd_turf_gangs_all$owner, replace=F) != cpd_turf_gangs_all$owner) / nrow(cpd_turf_gangs_all))
}

write_csv(sample_agreement %>% mean() %>% as.data.frame(), sample_agreement_ratio_path, col_names=FALSE)
