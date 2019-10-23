helperPath <- "../source/R/"
helperFiles <- list.files(helperPath)
for (i in helperFiles) {
  source(paste0(helperPath, i))
}

chi_shape_path <- "data/chicago_shp/"
chi_tracts_path <- "output/chi_tracts" # output once blocks have been added
chi_districts_path <- "output/chi_districts"

chi_clean_path <- "data/chi_clean.csv" # cleaned chicago crime data
chi_tsa_path <- "output/chi_tsa.csv" # tracts, shootings, all
chi_dsa_path <- "output/chi_dsa.csv"  # districts (combined), shootings, all

chi_tgeoid_path <- "output/chi_tgeoid.csv"
chi_dgeoid_path <- "output/chi_dgeoid.csv"
chi_geoid_cor_path <- "output/chi_geoid_cor.csv"

chi_tmatrix_path <- "output/chi_tmatrix.csv"  # tracts, aggregation given in 02_clean
chi_dmatrix_path <- "output/chi_dmatrix.csv"  # tracts, aggregation given in 02_clean

chi_tadjacency_path <- "output/chi_tadjacency.csv"
chi_dadjacency_path <- "output/chi_dadjacency.csv"

crimes_raw_url <- "https://www.dropbox.com/s/h7da81i9qt876tf/chi_crimes.csv?dl=1"
ss_raw_url <- "https://www.dropbox.com/s/3qfruwbsg1t7g23/shotspotter.csv?dl=1"