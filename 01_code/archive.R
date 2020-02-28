
geoids <- geoids %>% left_join(id_df)

chi_distr_counts <- chi_all %>% select(id, count)
chi_distr_ids <- chi_all %>% select(id, GEOID)

c <- 0

# TODO: alternative merge criterion - only combine if proposed district is smaller than certain upper limite
# will enforce more homogeneity between districts than we currently have
while(nrow(chi_distr_counts) > target) {
  
  chi_distr_counts <- chi_distr_counts %>% arrange(count)
  print(c)
  
  for (i in 1:nrow(chi_distr_counts)) {
    
    if (i <= nrow(chi_distr_counts)) {
      # loop through each district
      id <- chi_distr_counts$id[i]
      count <- chi_distr_counts$count[i]
      
      if (count <= c) {  # if count is low enough...
        
        neighbors <- rownames(adjacency)[which(adjacency[rownames(adjacency)==id, ] >= 1)] %>% as.numeric()  # get neighbors (gTouches)
        chi_distr_n <- chi_distr_counts %>% filter(id %in% neighbors)
        
        if (nrow(chi_distr_n) > 0) {
          for (j in 1:nrow(chi_distr_n)) {  # loop through each neighbor...
            count_n <- chi_distr_n[j, ]$count
            if (count_n <= c) {  # if neighbor count is low enough...
              id_n <- chi_distr_n[j, ]$id  # get id
              chi_distr_counts[chi_distr_counts$id == id, ]$count <- chi_distr_counts[chi_distr_counts$id == id, ]$count + count_n  # increase count for district "id"
              chi_distr_ids[chi_distr_ids$id == id_n, ]$id <- id  # associate district "id_n" GEOID with "id"
              chi_distr_counts <- chi_distr_counts %>% filter(id != id_n)  # remove district "id_n" from chi_distr_counts
              adjacency[rownames(adjacency)==id, ] <- adjacency[rownames(adjacency)==id, ] + adjacency[rownames(adjacency)==id_n, ]  # udpate adjacency matrix
              adjacency[ ,colnames(adjacency)==id] <- adjacency[ ,colnames(adjacency)==id] + adjacency[ ,colnames(adjacency)==id_n]  # udpate adjacency matrix
              adjacency <- adjacency[rownames(adjacency) != id_n, ]
              adjacency <- adjacency[ ,colnames(adjacency) != id_n]
              adjacency[rownames(adjacency)==id, colnames(adjacency)==id] <- 0
            }
          }
        }
        
      }
      
    }
  }
  
  c <- c + 1
  
}

# reconvert adjacency matrix to binary
adjacency[adjacency > 1] <- 1

# exports
write_csv(chi_distr_counts, chi_dsa_path)  # counts
write_csv(adjacency %>% as.data.frame(), chi_dadjacency_path, col_names=FALSE)  # reduced adjacency matrix
write_csv(chi_distr_ids, chi_geoid_cor_path)  # correspondence between ids

# recompute panel for districts
chi_agg <- chi_agg %>% left_join(chi_distr_ids)
chi_dagg <- chi_agg %>% group_by_("id", aggregation) %>% 
  summarise(count=sum(count)) %>% ungroup()
chi_dmat <- chi_dagg %>% spread_(aggregation, "count") %>% select(-id)
chi_dids <- chi_dagg %>% spread_(aggregation, "count") %>% select(id)

# export
write_csv(chi_dmat, chi_dmatrix_path, col_names=FALSE)  # district counts
write_csv(chi_dids, chi_dgeoid_path, col_names=FALSE)  # district geoids

# export new geography
chi_tracts <- geo_join(chi_tracts, chi_distr_ids, "GEOID", "GEOID")
chi_districts <- raster::aggregate(chi_tracts, by="id")

mkdir(chi_districts_path)
writeOGR(chi_districts, chi_districts_path, driver="ESRI Shapefile", layer='chi_districts', overwrite_layer=TRUE)
# NOTE: warnings ok, see https://github.com/r-spatial/sf/issues/306