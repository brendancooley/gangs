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
covar_y <- 2016 # year to take district covariates from

city <- "chicago"
period <- "all"

runBootstrap <- TRUE
L <- 100 # number of bootstrap iterations

### PATHS ###

# base paths

code_dir <- "01_code"
data_path_base <- "../02_data/"
output_path_base <- "../03_output/"
results_path_base <- "../04_results/"
figs_path_base <- "../05_figs/"
shiny_path <- "../shiny/"

data_path <- paste0(data_path_base, city, "/")
output_path <- paste0(output_path_base, city, "/")
results_path <- paste0(results_path_base, city, "/")
results_city_period_path <- paste0(results_path, period, "/")
bootstrap_path <- paste0(results_city_period_path, "bootstrap/")
figs_path <- paste0(figs_path_base, city, "/")

# data and output

shp_path <- paste0(data_path, city, "/shp/")
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

# geoids
geoids_path <- paste0(output_path, "geoids.csv")

# adjacency matrices
tadjacency_path <- paste0(output_path, "t_adjacency.csv")

# results

ts_period_path <- paste0(results_city_period_path, "ts_mat.csv")
ts_period_bs_path <- paste0(bootstrap_path, "ts_mat/")
geoids_keep_path <- paste0(results_city_period_path, "geoid_keep.csv")
geoids_keep_bs_path <- paste0(bootstrap_path, "geoid_keep/")
geoids_zero_path <- paste0(results_city_period_path, "geoid_zero.csv")  # geoids with no shootings to throw out of clustering
geoids_zero_bs_path <- paste0(bootstrap_path, "geoid_zero/")

cov_mat_path <- paste0(results_city_period_path, "cov_mat.csv")
clusters_path <- paste0(results_city_period_path, "clusters.csv")
nc_path <- paste0(results_city_period_path, "noise_cluster.csv")
P_path <- paste0(results_city_period_path, "P.csv")
P_sorted_path <- paste0(results_city_period_path, "P_sorted.csv")
J_path <- paste0(results_city_period_path, "J.csv")
eig_path <- paste0(results_city_period_path, "eig.csv")
Bhat_path <- paste0(results_city_period_path, "Bhat.csv")

# figures

hnfs_animated_path <- paste0(figs_path, "shootings_animated.gif")

### chicago ###

chi_shape_path <- paste0(data_path, "shp/")
chi_crimes_raw_url <- "https://www.dropbox.com/s/h7da81i9qt876tf/chi_crimes.csv?dl=1"

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


# save params
if (code_dir %in% strsplit(getwd(), "/")[[1]]) {
  save.image('params.Rdata')
}

# make directory structure

mkdir(data_path)
mkdir(output_path)
mkdir(bootstrap_path)
mkdir(results_path)
mkdir(results_city_period_path)
mkdir(ts_period_bs_path)
mkdir(covariates_path)
