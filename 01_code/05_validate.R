### SETUP ###

rm(list = ls())
invisible(lapply(paste0('package:', names(sessionInfo()$otherPkgs)), detach, character.only=TRUE, unload=TRUE))
source("00_params.R")
source("helpers.R")

libs <- c("tidyverse", "combinat")
ipak(libs)

### DATA ###

ownership <- list()

for (i in bruhn_sy:bruhn_ey) {
  ownership_y <- read_csv(paste0(gang_territory_path, i, ".csv"), col_names=FALSE)
  ownership[[i]] <- ownership_y
} 

geoids <- read_csv(paste0(gang_territory_path, "geoids.csv"), col_names=FALSE)
gang_names <- read_csv(paste0(gang_territory_path, "gang.names.csv"), col_names=FALSE)

cluster_binary <- read_csv(cluster_binary_path)

### CLEAN ###

gang_names_vec <- gang_names %>% pull(X1)
geoids_vec <- geoids %>% pull(X1)

ownership_mean <- Reduce("+", ownership[bruhn_sy:bruhn_ey]) / (length(ownership[bruhn_sy:bruhn_ey]))
ownership_mean <- t(ownership_mean)
colnames(ownership_mean) <- gang_names_vec
ownership_mean <- ownership_mean %>% as_tibble()
ownership_mean$GEOID <- geoids_vec
ownership_mean <- ownership_mean %>% select(GEOID, everything())

ownership_mean_long <- ownership_mean %>% pivot_longer(-GEOID, names_to="gang", values_to="share")
turf_size <- ownership_mean_long %>% group_by(gang) %>% summarise(turf=sum(share)) %>% arrange(desc(turf))
gang_order <- turf_size$gang

ownership_mean <- ownership_mean %>% select(GEOID, gang_order)

write_csv(ownership_mean, turf_shares_path)

### CONVERT TO BINARY OWNERSHIP MATRICES ###

ownership_all <- ownership_mean %>% select(-GEOID) %>% rowSums()
ownership_all <- ifelse(ownership_all > 1, 1, ownership_all)
ownership_mean$peaceful <- 1 - ownership_all

owner_id <- ownership_mean %>% select(-GEOID) %>% apply(1, function(x) which.max(x))
names <- setdiff(colnames(ownership_mean), "GEOID")
owner <- names[owner_id]
ownership_binary <- data.frame(ownership_mean$GEOID, owner) %>% as_tibble()
colnames(ownership_binary) <- c("GEOID", "owner")

write_csv(ownership_binary, turf_binary_path)

### METRICS ###

gangs_major <- colnames(ownership_mean[2:7])
ownership_binary$owner <- as.character(ownership_binary$owner)
ownership_binary$owner <- ifelse(ownership_binary$owner %in% c(gangs_major, "peaceful"), ownership_binary$owner, "other")

owners_all <- ownership_binary %>% pull(owner) %>% unique()
labels <- data.frame(owners_all, seq(1, length(owners_all)))
colnames(labels) <- c("owner", "gang_id")

ownership_binary <- ownership_binary %>% left_join(labels) %>% arrange(GEOID)
cluster_binary <- cluster_binary %>% arrange(GEOID)

permn_results <- permute_clusters(cluster_binary$cluster, ownership_binary$gang_id)
cluster_binary$assignment <- permn_results[[1]]
# table(cluster_binary$assignment)

cluster_binary <- cluster_binary %>% left_join(labels, by=c("assignment"="gang_id"))
cluster_binary %>% select(cluster, assignment, owner) %>% unique()

# NOTES
# for metric, do this on every bootstrap iteration
# but how to present map?
# check Jhat estimate...argmax is going to return wrong number with python indexing
