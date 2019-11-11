### SETUP ###

rm(list = ls())

if (!'chicago' %in% strsplit(getwd(), "/")[[1]]) {
  setwd('chicago')
}

source("params.R")
source("helpers.R")

libs <- c("tidyverse", "sp", "rgdal", "rgeos", "maptools", "tigris", "leaflet", "leaflet.extras", "spdep")
ipak(libs)

chi_clean <- read_csv(chi_clean_path) # %>% filter(hnfs==1)
chi_tracts <- readOGR(chi_tracts_path)

# week, month, year, all
chi_clean$all <- "all"

# number of districts at end of district aggregation
target <- 200

pop20102018 <- read_csv("https://www.dropbox.com/s/76t3iddlrtupul0/census20102018.csv?dl=1", skip=1)
pop20002010 <- read_csv("https://www.dropbox.com/s/oy1gtu7marwwoht/census20002010.csv?dl=1")

### POPULATION DATA ###

chicago_id <- 1714000
pop20002010$id <- paste0(pop20002010$STATE, pop20002010$PLACE)
pop20102018$id <- pop20102018$`Target Geo Id2`

chi_pop20002009 <- pop20002010 %>% filter(id==chicago_id, COUNTY=="000") %>% select(-SUMLEV, -STATE, -COUNTY, -PLACE, -COUSUB, -NAME, -STNAME, -ESTIMATESBASE2000, -id, -CENSUS2010POP, -POPESTIMATE2010)
chi_pop20102018 <- pop20102018 %>% filter(id==chicago_id) %>% select(-Id, -Id2, -Geography, -`Target Geo Id`, -`Target Geo Id2`, -Rank, -Geography_1, -Geography_2, -`April 1, 2010 - Census`, -`April 1, 2010 - Estimates Base`, -id)
chi_pop_y <- seq(2000, 2018)

chi_pop <- data.frame(chi_pop_y, c(t(chi_pop20002009), t(chi_pop20102018)))
colnames(chi_pop) <- c("year", "population")
write_csv(chi_pop, chi_pop_path)

### TAG CRIMES TO TRACTS (ALL) ###

chi_clean <- tag_crimes(chi_clean, chi_tracts)
# chi_clean %>% filter(is.na(GEOID))  # 41 events untagged
chi_clean <- chi_clean %>% filter(!is.na(GEOID))  # drop these from data

# all events
chi_clean_s <- chi_clean %>% filter(hnfs==1)
chi_clean_n <- chi_clean %>% filter(narcotics==1, arrest==1) # narcotics arrests

chi_all_s <- agg_crimes(chi_clean_s, "all")
chi_all_n <- agg_crimes(chi_clean_n, "all")  
write_csv(chi_all_s, chi_tsa_path)
write_csv(chi_all_n, chi_tna_path)

# by aggregation
# TODO group by hnfs versus narcotics as above under "all events"
chi_agg_s <- agg_crimes(chi_clean_s, aggregation)
chi_agg_n <- agg_crimes(chi_clean_n, aggregation)

# convert to matrix and vector storing geoid
chi_mat_s <- chi_agg_s %>% spread_(aggregation, "count") %>% select(-GEOID)
chi_geoid_s <- chi_agg_s %>% spread_(aggregation, "count") %>% select(GEOID)
chi_mat_n <- chi_agg_n %>% spread_(aggregation, "count") %>% select(-GEOID)
chi_geoid_n <- chi_agg_n %>% spread_(aggregation, "count") %>% select(GEOID)

write_csv(chi_mat_s, chi_ts_matrix_path, col_names=FALSE)
write_csv(chi_geoid_s, chi_ts_geoid_path, col_names=FALSE)
write_csv(chi_mat_n, chi_tn_matrix_path, col_names=FALSE)
write_csv(chi_geoid_n, chi_tn_geoid_path, col_names=FALSE)

### CONSTRUCT ADJACENCY MATRIX ###

adjacency <- poly2nb(chi_tracts, queen=FALSE)  # queen allows corner merges
adjacency <- nb2mat(adjacency)
adjacency[adjacency > 0] <- 1
# adjacency <- gTouches(chi_tracts, byid=T) * 1 # TODO: currently allowing corner merges, need to convert neighbors code if we use poly2nb

geoid_order <- chi_tracts@data$GEOID
id_df <- data.frame(geoid_order, seq(1, nrow(chi_all)))
colnames(id_df) <- c("GEOID", "id")

colnames(adjacency) <- seq(1, nrow(chi_all))
rownames(adjacency) <- seq(1, nrow(chi_all))
write_csv(adjacency %>% as.data.frame(), chi_tadjacency_path, col_names=FALSE)

chi_all <- chi_all %>% left_join(id_df)

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