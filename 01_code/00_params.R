# grab functions

helperPath <- "../source/R/"
helperFiles <- list.files(helperPath)
for (i in helperFiles) {
  source(paste0(helperPath, i))
}

# parameters

aggregation <- "month"
y_chunk <- 6
screeN <- 50

city <- "chicago"

# base paths

data_path_base <- "../02_data/"
output_path_base <- "../03_output/"
shiny_path <- "../shiny/"

data_path <- paste0(data_path_base, city, "/")
output_path <- paste0(output_path_base, city, "/")

# paths

tracts_path <- paste0(output_path, "tracts/") # output once blocks have been added
crimes_clean_path <- paste0(output_path, "crimes_clean.csv") # cleaned crime data
covariates_path <- paste0(output_path, "covariates/")

pop_path <- paste0(output_path, "population.csv")





chi_cov_path_pre <- "data/covariates" # income, population, etc by tract, tack year on end
chi_cov_path_pre_shiny <- "shiny/covariates"
chi_pop_path <- "data/population.csv"  # population by year


chi_tha_path <- "output/chi_tha.csv"  # tracts, homicides, all
chi_tsa_path <- "output/chi_tsa.csv" # tracts, shootings (including homicides), all
chi_tna_path <- "output/chi_tna.csv" # tracts, narcotics, all

chi_dsa_path <- "output/chi_dsa.csv"  # districts (combined), shootings, all

chi_t_geoid_path <- "output/chi_t_geoid.csv"
chi_dgeoid_path <- "output/chi_dgeoid.csv"
chi_geoid_cor_path <- "output/chi_geoid_cor.csv"

chi_th_matrix_path <- "output/chi_th_matrix.csv"  # tracts, aggregation given in 02_clean
chi_tn_matrix_path <- "output/chi_tn_matrix.csv"
chi_dmatrix_path <- "output/chi_dmatrix.csv"  # tracts, aggregation given in 02_clean

chi_tadjacency_path <- "output/chi_tadjacency.csv"
chi_dadjacency_path <- "output/chi_dadjacency.csv"

# clustering (all)
chi_clust_fpath <- "output/chi_ts_clust"
chi_clust_fpath_all <- paste0(chi_clust_fpath, "/", "all")
analysisSub <- chi_clust_fpath_all

chi_ts_matrix_y_file <- "chi_ts_matrix.csv"
chi_ts_matrix_path <- paste0(chi_clust_fpath_all, "/", chi_ts_matrix_y_file)

crimes_raw_url <- "https://www.dropbox.com/s/h7da81i9qt876tf/chi_crimes.csv?dl=1"
ss_raw_url <- "https://www.dropbox.com/s/3qfruwbsg1t7g23/shotspotter.csv?dl=1"



### chicago ###

chi_shape_path <- paste0(data_path, "shp/")

chicago_id <- 1714000  # for U.S. municipal population data

airport_ids <- c("17031980000", "17031980100", "17031990000")
drop_ids <- c("17031770700", "17031770602", "17031811701", "17031770800", "17031770500", "17031811600")  # Cook area surrounding airport

# representative suspected districts for each gang
vl_geoid <- "17031252202"
gd_geoid <- "17031671500"
lk_geoid <- "17031630800"

vl_col <- "#e3052a"
gd_col <- "#3794d7"
lk_col <- "#d3cb1c"
nc_col <- "#e3e3e5"
other_col <- "#8e178b"

### results ###

# end file names for clustering output...place in relevant chi_clust_fpath folder
J_path <- "J.csv"
eig_path <- "eig.csv"
cov_mat_path <- "cov_mat.csv"
P_path <- "P.csv"
P_sorted_path <- "P_sorted.csv"
geoid_keep_path <- "geoid_keep.csv"
geoid_zero_path <- "geoid_zero.csv"
clusters_path <- "clusters.csv"
nc_path <- "noise_cluster.csv"
Bhat_path <- "Bhat.csv"

# save for python

save.image('params.Rdata')

# make directory structure

mkdir(data_path)
mkdir(output_path)
mkdir(covariates_path)
