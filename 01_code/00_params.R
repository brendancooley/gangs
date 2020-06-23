# parameters

aggregation <- "month"
y_chunk <- 6
screeN <- 50
covar_y <- 2016 # year to take district covariates from

start_year <- 2001
end_year <- 2019

city <- "chicago"
period <- "all"

runBootstrap <- TRUE
L <- 100 # number of bootstrap iterations

bruhn_sy <- 2004 # bruhn start year
bruhn_ey <- 2017 # bruhn end year
gang_tract_thres <- .1  # gang must own at least this percent of tract to gain binary ownership
gangs_V <- 6  # number of gangs to include in validation

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

gang_correspondence_path <- paste0(data_path_base, "chicago/bruhn/gang_name_correspondence.csv")

# data and output

shp_path <- paste0(data_path, city, "/shp/")
tracts_path <- paste0(output_path, "tracts/") # output once blocks have been added
crimes_clean_path <- paste0(output_path, "crimes_clean.csv") # cleaned crime data
covariates_path <- paste0(output_path, "covariates/")
bruhn_path <- paste0(data_path, "bruhn/")
cpd_maps_path <- paste0(bruhn_path, "raw_maps/")

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

# cpd gang territorial shares by year
gang_territory_path <- paste0(output_path, "territory/")

turf_shares_path <- paste0(output_path, "turf_shares.csv")
turf_shares_sy_path <- paste0(output_path, "turf_shares_sy.csv")
turf_shares_ey_path <- paste0(output_path, "turf_shares_ey.csv")

turf_binary_path <- paste0(output_path, "turf_binary.csv")
turf_binary_sy_path <- paste0(output_path, "turf_binary_sy.csv")
turf_binary_ey_path <- paste0(output_path, "turf_binary_ey.csv")

cpd_gangs_N_path <- paste0(output_path, "cpd_gangs_N.csv")  # number of gangs after filtering by mean and threshold

# results

ts_period_path <- paste0(results_city_period_path, "ts_mat.csv")
ts_period_bs_path <- paste0(bootstrap_path, "ts_mat/")
geoids_keep_path <- paste0(results_city_period_path, "geoid_keep.csv")
geoids_keep_bs_path <- paste0(bootstrap_path, "geoid_keep/")
geoids_zero_path <- paste0(results_city_period_path, "geoid_zero.csv")  # geoids with no shootings to throw out of clustering
geoids_zero_bs_path <- paste0(bootstrap_path, "geoid_zero/")

cov_mat_path <- paste0(results_city_period_path, "cov_mat.csv")
cov_mat_bs_path <- paste0(bootstrap_path, "cov_mat/")
clusters_path <- paste0(results_city_period_path, "clusters.csv")
clusters_bs_path <- paste0(bootstrap_path, "clusters/")
nc_path <- paste0(results_city_period_path, "noise_cluster.csv")
nc_bs_path <- paste0(bootstrap_path, "noise_cluster/")
J_path <- paste0(results_city_period_path, "J.csv")
J_bs_path <- paste0(bootstrap_path, "J/")
J_all_path <- paste0(results_path, "J_all.csv")
Bhat_path <- paste0(results_city_period_path, "Bhat.csv")
Bhat_bs_path <- paste0(bootstrap_path, "Bhat/")

eig_path <- paste0(results_city_period_path, "eig.csv")
eig_bs_path <- paste0(bootstrap_path, "eig/")
P_path <- paste0(results_city_period_path, "P.csv")
P_sorted_path <- paste0(results_city_period_path, "P_sorted.csv")

Bhat_mean_path <- paste0(bootstrap_path, "Bhat_mean.csv")
Bhat_lb_path <- paste0(bootstrap_path, "Bhat_lb.csv")
Bhat_ub_path <- paste0(bootstrap_path, "Bhat_ub.csv")

cluster_props_path <- paste0(bootstrap_path, "cluster_props.csv")
cluster_props4_path <- paste0(bootstrap_path, "cluster_props4.csv")  # subset to K=4
cluster_binary_path <- paste0(bootstrap_path, "cluster_binary.csv")

label_counts_path <- paste0(results_path, "label_counts.csv")
gang_frac_path <- paste0(results_path, "gang_frac.csv")

cpd_agreement_ratio_path <- paste0(results_path, "cpd_agreement_ratio.csv")
cpd_agreement_ratio_gang_path <- paste0(results_path, "cpd_agreement_ratio_gang.csv")
cpd_agreement_ratio_peaceful_path <- paste0(results_path, "cpd_agreement_ratio_peaceful.csv")
sample_agreement_ratio_path <- paste0(results_path, "sample_agreement_ratio.csv")

# figures

hnfs_animated_path <- paste0(figs_path, "shootings_animated.gif")

### chicago ###

chi_shape_path <- paste0(data_path, "shp/")
# chi_crimes_raw_url <- "https://www.dropbox.com/s/h7da81i9qt876tf/chi_crimes.csv?dl=1"
chi_crimes_raw_url <- "https://data.cityofchicago.org/api/views/ijzp-q8t2/rows.csv?accessType=DOWNLOAD"

chicago_id <- 1714000  # for U.S. municipal population data

airport_ids <- c("17031980000", "17031980100", "17031990000")
drop_ids <- c("17031770700", "17031770602", "17031811701", "17031770800", "17031770500", "17031811600")  # Cook area surrounding airport

# representative suspected districts for each gang
# vl_geoid <- "17031252202"
# gd_geoid <- "17031671500"
# gd_geoid <- "17031834600"
# lk_geoid <- "17031630800"
# bps_geoid <- "17031460100"

vl_col <- "#e3052a"
gd_col <- "#3794d7"
lk_col <- "#d3cb1c"
bps_col <- "#8e178b"
ts_col <- "#88540b"  # two six
# sd_col <- "#2c493f"
bd_col <- "#2c493f" # black disciples
other_col <- "#C0C0C0"
nc_col <- "#ffffff"


# save params
if (code_dir %in% strsplit(getwd(), "/")[[1]]) {
  save.image('params.Rdata')
}

# grab functions

helperPath <- "../source/R/"
helperFiles <- list.files(helperPath)
for (i in helperFiles) {
  source(paste0(helperPath, i))
}


# make directory structure

mkdir(data_path)
mkdir(output_path)
mkdir(bootstrap_path)
mkdir(results_path)
mkdir(results_city_period_path)
mkdir(covariates_path)

# bootstrap folders
mkdir(ts_period_bs_path)
mkdir(geoids_keep_bs_path)
mkdir(geoids_zero_bs_path)
mkdir(cov_mat_bs_path)
mkdir(clusters_bs_path)
mkdir(nc_bs_path)
mkdir(J_bs_path)
mkdir(Bhat_bs_path)
mkdir(eig_bs_path)