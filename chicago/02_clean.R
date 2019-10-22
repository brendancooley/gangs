### SETUP ###

if (!'chicago' %in% strsplit(getwd(), "/")[[1]]) {
  setwd('chicago')
}

source("params.R")
source("helpers.R")

libs <- c("tidyverse", "sp")
ipak(libs)

chi_clean <- read_csv(chi_clean_path) %>% filter(hnfs==1)
chi_tracts <- readOGR(chi_tracts_path)

# week, month, year, all
aggregation <- "week"
chi_clean$all <- "all"

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
