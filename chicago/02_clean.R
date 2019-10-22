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

### TAG CRIMES TO TRACTS ###

chi_clean <- tag_crimes(chi_clean, chi_tracts)
# chi_clean %>% filter(is.na(GEOID))  # 41 events untagged
chi_clean <- chi_clean %>% filter(!is.na(GEOID))  # drop these from data

# all events
chi_all <- agg_crimes(chi_clean, "all")
write_csv(chi_all, chi_tsa_path)

# by aggregation
chi_agg <- agg_crimes(chi_clean, aggregation)

# convert to matrix and vector storing geoid
chi_mat <- chi_agg %>% spread(week, count) %>% select(-GEOID)
chi_geoid <- chi_agg %>% spread(week, count) %>% select(GEOID)

write_csv(chi_mat, chi_matrix_path)
write_csv(chi_geoid, chi_geoid_path)

### CONSTRUCT ADJACENCY MATRIX ###

adjacency <- gTouches(chi_tracts, byid=T) * 1
# to confirm, see cell (1, 2):
  # https://www.chicagocityscape.com/maps/index.php?place=censustract-17031221000
  # https://www.chicagocityscape.com/maps/index.php?place=censustract-17031221100

chi_all$id <- seq(1, nrow(chi_all))

chi_distr_counts <- chi_all %>% select(id, count)
chi_distr_ids <- chi_all %>% select(id, GEOID)

c <- 0

while(nrow(chi_distr_counts) > target) {
  
  chi_distr_counts <- chi_distr_counts %>% arrange(count)
  
  for (i in 1:nrow(chi_distr_counts)) {
    
    print(c)
    
    if (i <= nrow(chi_distr_counts)) {
      # loop through each district
      id <- chi_distr_counts$id[i]
      count <- chi_distr_counts$count[i]

      if (count <= c) {  # if count is low enough...
        
        # TODO this is the problem...need to update which districts adjacency matrix grabs
        # perhaps solution is to just collapse it whenever we strike a district
        neighbors <- which(adjacency[id, ] == 1) %>% as.numeric()  # get neighbors
        chi_distr_n <- chi_distr_counts %>% filter(id %in% neighbors)
        
        if (nrow(chi_distr_n) > 0) {
          for (j in 1:nrow(chi_distr_n)) {  # loop through each neighbor...
            count_n <- chi_distr_n[j, ]$count
            if (count_n <= c) {  # if neighbor count is low enough...
              id_n <- chi_distr_n[j, ]$id  # get id
              chi_distr_counts$count[i] <- chi_distr_counts$count[i] + count_n  # increase count for district "id"
              print("id_n:")
              print(chi_distr_ids[chi_distr_ids$id == id_n, ])
              print("id:")
              print(chi_distr_ids[chi_distr_ids$id == id, ])
              chi_distr_ids[chi_distr_ids$id == id_n, ]$id <- id  # associate district "id_n" GEOID with "id"
              print("id:")
              print(chi_distr_ids[chi_distr_ids$id == id, ])
              chi_distr_counts <- chi_distr_counts %>% filter(id != id_n)  # remove district "id_n" from chi_distr_counts
              adjacency[id, ] <- adjacency[id, ] + adjacency[id_n, ]  # udpate adjacency matrix
            }
          }
        }
        
      }
      
    }
  }
  
  c <- c + 1
  
}

chi_distr_counts %>% arrange(count) %>% pull(id) %>% sort()
chi_distr_ids %>% pull(id) %>% unique() %>% sort()
# TODO: lengths don't match...don't seem to be updating chi_distr_ids properly
chi_tracts <- geo_join(chi_tracts, chi_distr_ids, "GEOID", "GEOID")

chi_tracts_union <- unionSpatialPolygons(chi_tracts, chi_tracts$id)
chi_tracts_union$id <- chi_tracts$id

popup <- paste0("GEOID: ", chi_tracts_union$id)

map <- leaflet() %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addPolygons(data = chi_tracts, 
              color = "#b2aeae", # you need to use hex colors
              fillOpacity = 0.7, 
              weight = 1, 
              smoothFactor = 0.2)
map
