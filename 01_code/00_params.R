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

# counts of homicides, shootings, and narcotics by geoid
tha_path <- paste0(output_path, "tha.csv")  # tracts, homicides, all
tsa_path <- paste0(output_path, "tsa.csv") # tracts, shootings (including homicides), all
tna_path <- paste0(output_path, "tna.csv") # tracts, narcotics, all

# matrics of homicides, shootings, and narcotics
th_mat_path <- paste0(output_path, "th_mat.csv")  # matrix of homicides per tract (row) by aggregation (column)
tn_mat_path <- paste0(output_path, "tn_mat.csv") # matrix of narcotics per tract (row) by aggregation (column)
ts_mat_path <- paste0(output_path, "ts_mat.csv") # matrix of hnfs per tract (row) by aggregation (column)

# year chunk path
ts_chunk_path <- paste0(output_path, "ts_mat_")  # need to append year and .csv in cleaning

# geoids
geoids_path <- paste0(output_path, "geoids.csv")

# adjacency matrices
tadjacency_path <- paste0(output_path, "t_adjacency.csv")




### STOPPING POINT ###



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
