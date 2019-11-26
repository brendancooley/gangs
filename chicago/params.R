
helperPath <- "../source/R/"
helperFiles <- list.files(helperPath)
for (i in helperFiles) {
  source(paste0(helperPath, i))
}

aggregation <- "month"

airport_ids <- c("17031980000", "17031980100", "17031990000")
drop_ids <- c("17031770700", "17031770602", "17031811701", "17031770800", "17031770500", "17031811600")  # Cook area surrounding airport

chi_shape_path <- "data/chicago_shp/"
chi_tracts_path <- "output/chi_tracts" # output once blocks have been added
chi_districts_path <- "output/chi_districts"

chi_cov_path_pre <- "data/covariates" # income, population, etc by tract, tack year on end
chi_cov_path_pre_shiny <- "shiny/covariates"
chi_pop_path <- "data/population.csv"  # population by year

chi_clean_path <- "data/chi_clean.csv" # cleaned chicago crime data

chi_tha_path <- "output/chi_tha.csv"  # tracts, homicides, all
chi_tsa_path <- "output/chi_tsa.csv" # tracts, shootings (including homicides), all
chi_tna_path <- "output/chi_tna.csv" # tracts, narcotics, all

chi_dsa_path <- "output/chi_dsa.csv"  # districts (combined), shootings, all

chi_t_geoid_path <- "output/chi_t_geoid.csv"
chi_dgeoid_path <- "output/chi_dgeoid.csv"
chi_geoid_cor_path <- "output/chi_geoid_cor.csv"

chi_th_matrix_path <- "output/chi_th_matrix.csv"  # tracts, aggregation given in 02_clean
chi_ts_matrix_path <- "output/chi_ts_matrix.csv"  # tracts, aggregation given in 02_clean
chi_tn_matrix_path <- "output/chi_tn_matrix.csv"
chi_dmatrix_path <- "output/chi_dmatrix.csv"  # tracts, aggregation given in 02_clean

chi_tadjacency_path <- "output/chi_tadjacency.csv"
chi_dadjacency_path <- "output/chi_dadjacency.csv"

crimes_raw_url <- "https://www.dropbox.com/s/h7da81i9qt876tf/chi_crimes.csv?dl=1"
ss_raw_url <- "https://www.dropbox.com/s/3qfruwbsg1t7g23/shotspotter.csv?dl=1"

cov_mat_path = "output/cov_mat.csv"
geoid_keep_path = "output/geoid_keep.csv"
geoid_zero_path = "output/geoid_zero.csv"
clusters_path = "output/clusters.csv"
nc_path = "output/noise_cluster.csv"

save.image('params.Rdata')

