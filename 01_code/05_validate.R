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

ownership_mean <- Reduce("+", ownership[bruhn_sy:bruhn_ey]) / (length(ownership[bruhn_sy:bruhn_ey]))
ownership_mean <- t(ownership_mean)
colnames(ownership_mean) <- gang_names_vec
ownership_mean <- ownership_mean %>% as_tibble()
ownership_mean$GEOID <- geoids_vec
ownership_mean <- ownership_mean %>% select(GEOID, everything())

ownership_mean_long <- ownership_mean %>% pivot_longer(-GEOID, names_to="gang", values_to="share")
# turf_size <- ownership_mean_long %>% group_by(gang) %>% summarise(turf=sum(share)) %>% arrange(desc(turf))
# turf_size %>% print(n=100)
# gang_order <- turf_size$gang

# subset to major gangs
ownership_mean_long <- ownership_mean_long %>% filter(gang %in% major_gangs)

ownership_mean <- ownership_mean_long %>% pivot_wider(id_cols=c("GEOID", "gang"), names_from="gang", values_from="share")
# ownership_mean <- ownership_mean %>% select(GEOID, gang_order)

write_csv(ownership_mean, turf_shares_path)

### CONVERT TO BINARY OWNERSHIP MATRICES ###

# ownership_all <- ownership_mean %>% select(-GEOID) %>% rowSums()
# ownership_all <- ifelse(ownership_all > 1, 1, ownership_all)
# ownership_mean$peaceful <- 1 - ownership_all

owner_id <- ownership_mean %>% select(-GEOID) %>% apply(1, function(x) which.max(x))
owner_frac <- ownership_mean %>% select(-GEOID) %>% apply(1, function(x) max(x))
names <- setdiff(colnames(ownership_mean), "GEOID")
owner <- names[owner_id]
ownership_binary <- data.frame(ownership_mean$GEOID, owner, owner_frac) %>% as_tibble()
colnames(ownership_binary) <- c("GEOID", "owner", "owner_prop")
ownership_binary$owner <- ownership_binary$owner %>% as.character()
ownership_binary$owner <- ifelse(ownership_binary$owner_prop < gang_tract_thres, "peaceful", ownership_binary$owner)

write_csv(ownership_binary, turf_binary_path)
