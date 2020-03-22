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

major_gangs <- read_csv(paste0(gang_territory_path, "major_gangs.csv"), col_names=FALSE) %>% pull(.)

### CLEAN ###

gang_names_vec <- gang_names %>% pull(X1)
geoids_vec <- geoids %>% pull(X1)

ownership_sy <- ownership[[bruhn_sy]]
ownership_ey <- ownership[[bruhn_ey]]

ownership_mean <- Reduce("+", ownership[bruhn_sy:bruhn_ey]) / (length(ownership[bruhn_sy:bruhn_ey]))
ownership_mean <- t(ownership_mean)
ownership_sy <- t(ownership_sy)
ownership_ey <- t(ownership_ey)

colnames(ownership_mean) <- gang_names_vec
colnames(ownership_sy) <- gang_names_vec
colnames(ownership_ey) <- gang_names_vec

ownership_mean <- ownership_mean %>% as_tibble()
ownership_sy <- ownership_sy %>% as_tibble()
ownership_ey <- ownership_ey %>% as_tibble()

ownership_mean$GEOID <- geoids_vec
ownership_sy$GEOID <- geoids_vec
ownership_ey$GEOID <- geoids_vec

ownership_mean <- ownership_mean %>% select(GEOID, everything())
ownership_sy <- ownership_sy %>% select(GEOID, everything())
ownership_ey <- ownership_ey %>% select(GEOID, everything())

# calculate number of unique qualifying gangs
cp_mat <- ownership_mean %>% dplyr::select(-c("GEOID")) %>% as.matrix()
ownership_mean_test <- ownership_mean
ownership_mean_test$max_id <- colnames(ownership_mean %>% dplyr::select(-GEOID))[apply(cp_mat, 1, which.max)]
ownership_mean_test$owner_prop <- apply(cp_mat, 1, max)
ownership_mean_test %>% select(GEOID, max_id, owner_prop)
ownership_mean_test <- ownership_mean_test %>% filter(owner_prop > gang_tract_thres)
cpd_gangs_N <- table(ownership_mean_test$max_id) %>% length()

write_csv(cpd_gangs_N %>% as.data.frame(), cpd_gangs_N_path)

ownership_mean_long <- ownership_mean %>% pivot_longer(-GEOID, names_to="gang", values_to="share")
ownership_sy_long <- ownership_sy %>% pivot_longer(-GEOID, names_to="gang", values_to="share")
ownership_ey_long <- ownership_ey %>% pivot_longer(-GEOID, names_to="gang", values_to="share")

# ownership_mean_long$gang <- ifelse(ownership_mean_long$gang %in% major_gangs, ownership_mean_long$gang, "other")
# ownership_mean_long <- ownership_mean_long %>% group_by(gang, GEOID) %>% summarise(share=sum(share)) %>% arrange(GEOID)
# turf_size %>% print(n=100)
# gang_order <- turf_size$gang

# subset to major gangs
ownership_mean_long <- ownership_mean_long %>% filter(gang %in% major_gangs)
ownership_sy_long <- ownership_sy_long %>% filter(gang %in% major_gangs)
ownership_ey_long <- ownership_ey_long %>% filter(gang %in% major_gangs)


ownership_mean <- ownership_mean_long %>% pivot_wider(id_cols=c("GEOID", "gang"), names_from="gang", values_from="share")
ownership_sy <- ownership_sy_long %>% pivot_wider(id_cols=c("GEOID", "gang"), names_from="gang", values_from="share")
ownership_ey <- ownership_ey_long %>% pivot_wider(id_cols=c("GEOID", "gang"), names_from="gang", values_from="share")


# ownership_mean <- ownership_mean %>% select(GEOID, gang_order)

write_csv(ownership_mean, turf_shares_path)
write_csv(ownership_sy, turf_shares_sy_path)
write_csv(ownership_ey, turf_shares_ey_path)


### CONVERT TO BINARY OWNERSHIP MATRICES ###

# ownership_all <- ownership_mean %>% select(-GEOID) %>% rowSums()
# ownership_all <- ifelse(ownership_all > 1, 1, ownership_all)
# ownership_mean$peaceful <- 1 - ownership_all

# mean

owner_id <- ownership_mean %>% select(-GEOID) %>% apply(1, function(x) which.max(x))
owner_frac <- ownership_mean %>% select(-GEOID) %>% apply(1, function(x) max(x))
names <- setdiff(colnames(ownership_mean), "GEOID")
owner <- names[owner_id]
ownership_binary <- data.frame(ownership_mean$GEOID, owner, owner_frac) %>% as_tibble()
colnames(ownership_binary) <- c("GEOID", "owner", "owner_prop")
ownership_binary$owner <- ownership_binary$owner %>% as.character()
ownership_binary$owner <- ifelse(ownership_binary$owner_prop < gang_tract_thres, "peaceful", ownership_binary$owner)

write_csv(ownership_binary, turf_binary_path)

# start year

owner_id <- ownership_sy %>% select(-GEOID) %>% apply(1, function(x) which.max(x))
owner_frac <- ownership_sy %>% select(-GEOID) %>% apply(1, function(x) max(x))
names <- setdiff(colnames(ownership_sy), "GEOID")
owner <- names[owner_id]
ownership_binary_sy <- data.frame(ownership_sy$GEOID, owner, owner_frac) %>% as_tibble()
colnames(ownership_binary_sy) <- c("GEOID", "owner", "owner_prop")
ownership_binary_sy$owner <- ownership_binary_sy$owner %>% as.character()
ownership_binary_sy$owner <- ifelse(ownership_binary_sy$owner_prop < gang_tract_thres, "peaceful", ownership_binary_sy$owner)

write_csv(ownership_binary_sy, turf_binary_sy_path)

# end year

owner_id <- ownership_ey %>% select(-GEOID) %>% apply(1, function(x) which.max(x))
owner_frac <- ownership_ey %>% select(-GEOID) %>% apply(1, function(x) max(x))
names <- setdiff(colnames(ownership_ey), "GEOID")
owner <- names[owner_id]
ownership_binary_ey <- data.frame(ownership_ey$GEOID, owner, owner_frac) %>% as_tibble()
colnames(ownership_binary_ey) <- c("GEOID", "owner", "owner_prop")
ownership_binary_ey$owner <- ownership_binary_ey$owner %>% as.character()
ownership_binary_ey$owner <- ifelse(ownership_binary_ey$owner_prop < gang_tract_thres, "peaceful", ownership_binary_ey$owner)

write_csv(ownership_binary_ey, turf_binary_ey_path)