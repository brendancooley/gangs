helperPath <- "../source/R/"
helperFiles <- list.files(helperPath)
for (i in helperFiles) {
  source(paste0(helperPath, i))
}

chi_shape_path <- "data/chicago_shp/"
chi_tracts_path <- "output/chi_tracts" # output once blocks have been added
chi_clean_path <- "data/chi_clean.csv" # cleaned chicago crime data
chi_tsa_path <- "output/chi_tsa.csv" # tracts, shootings, all
chi_geoid_path <- "output/chi_geoid.csv"
chi_matrix_path <- "output/chi_matrix.csv"

crimes_raw_url <- "https://www.dropbox.com/s/h7da81i9qt876tf/chi_crimes.csv?dl=1"
ss_raw_url <- "https://www.dropbox.com/s/3qfruwbsg1t7g23/shotspotter.csv?dl=1"