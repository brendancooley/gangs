### SETUP ###

rm(list = ls())
invisible(lapply(paste0('package:', names(sessionInfo()$otherPkgs)), detach, character.only=TRUE, unload=TRUE))
source("00_params.R")

libs <- c("tidyverse")
ipak(libs)

### DATA ###

ownership <- list()

for (i in bruhn_sy:bruhn_ey) {
  ownership_y <- read_csv(paste0(gang_territory_path, i, ".csv"), col_names=FALSE)
  ownership[[i]] <- ownership_y
} 

geoids <- read_csv(paste0(gang_territory_path, "geoids.csv"), col_names=FALSE)
gang_names <- read_csv(paste0(gang_territory_path, "gang.names.csv"), col_names=FALSE)

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














### SCRATCH ###

ownership2004 <- ownership[[2004]]
colnames(ownership2004) <- geoids_vec

colSums(ownership2004)[colSums(ownership2004) > 1.01]
inds <- geoids_vec[colSums(ownership2004) > 1.01]
ownership2004_sub <- ownership2004[colnames(ownership2004)%in%inds]

overlaps <- list()
for (i in 1:ncol(ownership2004_sub)) {
  gangs_i <- gang_names_vec[which(ownership2004_sub[,i] > 0)]
  overlaps[[i]] <- gangs_i
}
