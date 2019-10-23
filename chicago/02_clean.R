### SETUP ###

if (!'chicago' %in% strsplit(getwd(), "/")[[1]]) {
  setwd('chicago')
}

source("params.R")
source("helpers.R")

libs <- c("tidyverse", "sp", "rgdal", "rgeos", "maptools", "tigris", "leaflet", "leaflet.extras")
ipak(libs)

chi_clean <- read_csv(chi_clean_path) %>% filter(hnfs==1)
chi_tracts <- readOGR(chi_tracts_path)

# week, month, year, all
aggregation <- "week"
chi_clean$all <- "all"

# number of districts at end of aggregation
target <- 200

### TAG CRIMES TO TRACTS (ALL) ###

chi_clean <- tag_crimes(chi_clean, chi_tracts)
# chi_clean %>% filter(is.na(GEOID))  # 41 events untagged
chi_clean <- chi_clean %>% filter(!is.na(GEOID))  # drop these from data

# all events
chi_all <- agg_crimes(chi_clean, "all")
write_csv(chi_all, chi_tsa_path)

# by aggregation
chi_agg <- agg_crimes(chi_clean, aggregation)

# convert to matrix and vector storing geoid
chi_mat <- chi_agg %>% spread_(aggregation, "count") %>% select(-GEOID)
chi_geoid <- chi_agg %>% spread_(aggregation, "count") %>% select(GEOID)

write_csv(chi_mat, chi_matrix_path)
write_csv(chi_geoid, chi_tgeoid_path)

### CONSTRUCT ADJACENCY MATRIX ###

adjacency <- gTouches(chi_tracts, byid=T) * 1
colnames(adjacency) <- seq(1, nrow(chi_all))
rownames(adjacency) <- seq(1, nrow(chi_all))
write_csv(adjacency %>% as.data.frame(), chi_tadjacency_path, col_names=FALSE)

chi_all$id <- seq(1, nrow(chi_all))

chi_distr_counts <- chi_all %>% select(id, count)
chi_distr_ids <- chi_all %>% select(id, GEOID)

c <- 0

while(nrow(chi_distr_counts) > target) {
  
  chi_distr_counts <- chi_distr_counts %>% arrange(count)
  print(c)
  
  for (i in 1:nrow(chi_distr_counts)) {
    
    if (i <= nrow(chi_distr_counts)) {
      # loop through each district
      id <- chi_distr_counts$id[i]
      count <- chi_distr_counts$count[i]

      if (count <= c) {  # if count is low enough...
        
        # TODO this is the problem...need to update which districts adjacency matrix grabs
        # perhaps solution is to just collapse it whenever we strike a district
        neighbors <- rownames(adjacency)[which(adjacency[rownames(adjacency)==id, ] >= 1)] %>% as.numeric()  # get neighbors
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
  summarise(count=n()) %>% ungroup()
chi_dmat <- chi_dagg %>% spread_(aggregation, "count") %>% select(-id)
chi_dids <- chi_dagg %>% spread_(aggregation, "count") %>% select(id)

# export
write_csv(chi_dmat, chi_dmatrix_path)  # district counts
write_csv(chi_dids, chi_dgeoid_path)  # district geoids

# export new geography
chi_tracts <- geo_join(chi_tracts, chi_distr_ids, "GEOID", "GEOID")
chi_districts <- raster::aggregate(chi_tracts, by="id")

if (!dir.exists(chi_districts_path)) {
  mkdir(chi_districts_path)
  writeOGR(chi_districts, chi_districts_path, driver="ESRI Shapefile", layer='chi_districts')
  # NOTE: warnings ok, see https://github.com/r-spatial/sf/issues/306
}


### TEST BAY ###

chi_all <- chi_all %>% select(-id)
chi_all <- chi_all %>% left_join(chi_distr_ids)
chi_all %>% filter(id==667)
