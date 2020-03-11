tag_crimes <- function(crimes, geography) {
  
  # transform crime into spatial data that matches the CRS of geography
  crimes_geo <- crimes
  coordinates(crimes_geo) <- ~lng+lat
  proj4string(crimes_geo) <- proj4string(geography)
  
  # Mapping crime events to districts
  crimes_geoids <- over(crimes_geo, geography) %>% as_tibble()
  crimes$GEOID <- crimes_geoids$GEOID  # append geoids to crimes
  
  return(crimes)
}

agg_crimes <- function(crimes_tagged, aggregation) {
  
  # create blank template matrix for all spatial-temporal combinations
  GEOID <- crimes_tagged$GEOID
  unit <- crimes_tagged[[aggregation]] %>% unique() %>% sort()
  
  crimes_blank <- crossing(GEOID, unit)
  colnames(crimes_blank)[colnames(crimes_blank)=="unit"] <- aggregation
  crimes_blank$count <- NA
  crimes_blank$count <- as.integer(crimes_blank$count)
  
  # summarize counts
  crimes_agg <- crimes_tagged %>% group_by_("GEOID", aggregation) %>%
    summarise(count=n()) %>% ungroup()
  
  # aggregate and merge
  crimes_agg_all <- crimes_blank %>% left_join(crimes_agg, by=c("GEOID", aggregation)) %>% 
    mutate(count = coalesce(count.x, count.y)) %>% 
    dplyr::select(-count.x, -count.y)
  
  # replace NA with zero
  crimes_agg_all$count <- ifelse(is.na(crimes_agg_all$count), 0, crimes_agg_all$count)
  
  return(crimes_agg_all)
  
}

permute_clusters <- function(clusters_i, clusters_base) {
  
  permutations <- do.call(cbind, permn(unique(clusters_i)))
  permutations_c <- apply(permutations, 2, function(x) x[clusters_i])
  dim(permutations_c)
  
  Loss <- c()
  for (j in 1:ncol(permutations_c)) {
    loss <- sum(abs(permutations_c[,j] - clusters_base))
    Loss <- c(Loss, loss)
  }
  clusters <- permutations_c[,which.min(Loss)]
  labels <- permutations[,which.min(Loss)]
  
  return(list("clusters"=clusters, "labels"=labels))
}