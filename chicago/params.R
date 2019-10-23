helperPath <- "../source/R/"
helperFiles <- list.files(helperPath)
for (i in helperFiles) {
  source(paste0(helperPath, i))
}

chi_shape_path <- "data/chicago_shp/"
chi_tracts_path <- "output/chi_tracts" # output once blocks have been added
chi_clean_path <- "data/chi_clean.csv" # cleaned chicago crime data
chi_tsa_path <- "output/chi_tsa.csv" # tracts, shootings, all
chi_tgeoid_path <- "output/chi_tgeoid.csv"
chi_tmatrix_path <- "output/chi_tmatrix.csv"  # tracts, aggregation given in 02_clean
chi_psa_path <- "output/chi_psa.csv"  # polygons (combined), shootings, all
chi_pmatrix_path <- "output/chi_pmatrix.csv"  # tracts, aggregation given in 02_clean

crimes_raw_url <- "https://www.dropbox.com/s/h7da81i9qt876tf/chi_crimes.csv?dl=1"
ss_raw_url <- "https://www.dropbox.com/s/3qfruwbsg1t7g23/shotspotter.csv?dl=1"