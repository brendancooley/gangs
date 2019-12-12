### SETUP ###

import numpy as np
import imp
import time
import os
import pyreadr
import matplotlib.pyplot as plt

import helpers
imp.reload(helpers)

paths = pyreadr.read_r('params.RData') # also works for Rds

chi_ts_matrix_y_file = paths['chi_ts_matrix_y_file'].iloc[0, 0]
chi_t_geoid_path = paths['chi_t_geoid_path'].iloc[0, 0]
geoid_keep_path = paths['geoid_keep_path'].iloc[0, 0]
geoid_zero_path = paths['geoid_zero_path'].iloc[0, 0]
cov_mat_path = paths['cov_mat_path'].iloc[0, 0]
clusters_path = paths['clusters_path'].iloc[0, 0]
chi_tadjacency_path = paths['chi_tadjacency_path'].iloc[0, 0]
nc_path = paths['nc_path'].iloc[0, 0]
P_path = paths['P_path'].iloc[0, 0]
P_sorted_path = paths['P_sorted_path'].iloc[0, 0]
K_path = paths['K_path'].iloc[0, 0]

chi_clust_fpath = paths['chi_clust_fpath'].iloc[0, 0]
groups = [f for f in os.listdir(chi_clust_fpath) if not f.startswith('.')]

C = np.genfromtxt(chi_tadjacency_path, delimiter=",")  # adjacency matrix
geoids = np.genfromtxt(chi_t_geoid_path, delimiter=",")

V = 3 # number of folds for cross validation

### CLUSTERING ###

groups = ["all"]  # stick to everything for now, commenting this out gives estimates for 5-year subsets

for i in groups:

    i = groups[0]

    folder_active = chi_clust_fpath + "/" + i

    counts = np.genfromtxt(folder_active + "/" + chi_ts_matrix_y_file, delimiter=",")

    covM = helpers.covMat(counts, zero=False, cor=False)  # construct covariance matrix
    # plt.imshow(covM, cmap="hot", interpolation="nearest")

    P0 = covM - np.diag(np.diag(covM))
    # plt.imshow(P0, cmap="hot", interpolation="nearest")

    geoids_zero = geoids[np.argwhere(np.sum(P0, axis=0)==0)]  # district ids to drop from analysis (no covariance)
    geoids_keep = geoids[np.argwhere(np.sum(P0, axis=0)!=0)]
    np.savetxt(folder_active + "/" + geoid_zero_path, geoids_zero)
    np.savetxt(folder_active + "/" + geoid_keep_path, geoids_keep)

    P = P0[np.sum(P0, axis=0)!=0,:]
    P = P[:,np.sum(P0, axis=0)!=0]
    # plt.imshow(P, cmap="hot", interpolation="nearest")
    np.savetxt(folder_active + "/" + P_path, P, delimiter=',', fmt='%f')

    # CLUSTERING #
    # imp.reload(helpers)
    M = helpers.est_J(P, V, S=50)
    np.savetxt(folder_active + "/" + K_path, np.array([M]), delimiter=",")
    # clusters = helpers.spect_clust(P, M, normalize=True, eig_plot=True)
    clusters, centroids = helpers.spect_clust(P, M, normalize=False, eig_plot=True)
    np.bincount(clusters)
    theta = np.eye(M)[clusters]
    X = centroids
    Bhat = helpers.Bhat(P, X, M)  # estimate of connectivity matrix
    # np.linalg.norm(Bhat, axis=1)

    noise_cluster = np.array([np.argmin(np.linalg.norm(Bhat, axis=1))])

    np.savetxt(folder_active + "/" + clusters_path, clusters, delimiter=",")
    np.savetxt(folder_active + "/" + nc_path, noise_cluster, delimiter=",")

    P_sorted = helpers.permute_covM(P, clusters, nc=noise_cluster)
    # plt.imshow(P_sorted, cmap="hot", interpolation="nearest")
    np.savetxt(folder_active + "/" + P_sorted_path, P_sorted, delimiter=',', fmt='%f')






### WORKING ###

folder_active = chi_clust_fpath + "/" + "all"

counts = np.genfromtxt(folder_active + "/" + chi_ts_matrix_y_file, delimiter=",")

covM = helpers.covMat(counts, zero=False, cor=False)  # construct covariance matrix
# plt.imshow(covM, cmap="hot", interpolation="nearest")

P0 = covM - np.diag(np.diag(covM))
lbda, U = np.linalg.eigh(covM)
lbda, U = np.linalg.eigh(P0)
# NOTE: P doesn't remain PSD when we drop the diagonal

# plt.imshow(P0, cmap="hot", interpolation="nearest")

geoids_zero = geoids[np.argwhere(np.sum(P0, axis=0)==0)]  # district ids to drop from analysis (no covariance)
geoids_keep = geoids[np.argwhere(np.sum(P0, axis=0)!=0)]
np.savetxt(folder_active + "/" + geoid_zero_path, geoids_zero)
# np.savetxt(geoid_keep_path, geoids_keep)

P = P0[np.sum(P0, axis=0)!=0,:]
P = P[:,np.sum(P0, axis=0)!=0]
plt.imshow(P, cmap="hot", interpolation="nearest")
np.savetxt(folder_active + "/" + P_path, P)

# CLUSTERING #
# imp.reload(helpers)
M = 2
# clusters = helpers.spect_clust(P, M, normalize=True, eig_plot=True)
clusters, centroids = helpers.spect_clust(P, M, normalize=False, eig_plot=True)

lbda, U = np.linalg.eigh(P)

theta = np.eye(M+1)[clusters]
X = centroids
Bhat = helpers.Bhat(P, X, M)  # estimate of connectivity matrix
# np.linalg.norm(Bhat, axis=1)

noise_cluster = np.array([np.argmin(np.linalg.norm(Bhat, axis=1))])

np.savetxt(folder_active + "/" + clusters_path, clusters, delimiter=",")
np.savetxt(folder_active + "/" + nc_path, noise_cluster, delimiter=",")

P_sorted = helpers.permute_covM(P, clusters, nc=noise_cluster)
plt.imshow(P_sorted, cmap="hot", interpolation="nearest")
np.savetxt(folder_active + "/" + P_sorted_path, P_sorted)
