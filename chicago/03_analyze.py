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

chi_ts_matrix_path = paths['chi_ts_matrix_path'].iloc[0, 0]
chi_t_geoid_path = paths['chi_t_geoid_path'].iloc[0, 0]
geoid_keep_path = paths['geoid_keep_path'].iloc[0, 0]
geoid_zero_path = paths['geoid_zero_path'].iloc[0, 0]
cov_mat_path = paths['cov_mat_path'].iloc[0, 0]
clusters_path = paths['clusters_path'].iloc[0, 0]
chi_tadjacency_path = paths['chi_tadjacency_path'].iloc[0, 0]
nc_path = paths['nc_path'].iloc[0, 0]

C = np.genfromtxt(chi_tadjacency_path, delimiter=",")  # adjacency matrix

counts = np.genfromtxt(chi_ts_matrix_path, delimiter=",")
geoids = np.genfromtxt(chi_t_geoid_path, delimiter=",")

covM = helpers.covMat(counts, zero=False, cor=False)  # construct covariance matrix
plt.imshow(covM, cmap="hot", interpolation="nearest")

P0 = covM - np.diag(np.diag(covM))
plt.imshow(P0, cmap="hot", interpolation="nearest")

geoids_zero = geoids[np.argwhere(np.sum(P0, axis=0)==0)]  # district ids to drop from analysis (no covariance)
geoids_keep = geoids[np.argwhere(np.sum(P0, axis=0)!=0)]
np.savetxt(geoid_zero_path, geoids_zero)
np.savetxt(geoid_keep_path, geoids_keep)

P = P0[np.sum(P0, axis=0)!=0,:]
P = P[:,np.sum(P0, axis=0)!=0]
plt.imshow(P, cmap="hot", interpolation="nearest")


### CLUSTERING ###
imp.reload(helpers)
M = 2
# clusters = helpers.spect_clust(P, M, normalize=True, eig_plot=True)
clusters, centroids = helpers.spect_clust(P, M, normalize=False, eig_plot=True)
theta = np.eye(M+1)[clusters]
X = centroids

lbda, U = np.linalg.eigh(P)
lbda_K = np.flip(np.argsort(lbda))[0:M+1]
Lbda = np.diag(lbda[lbda_K])

Bhat = np.matmul(np.matmul(X, Lbda), X.T)  # estimate of connectivity matrix
# np.linalg.norm(Bhat, axis=1)

noise_cluster = np.array([np.argmin(np.linalg.norm(Bhat, axis=1))])
# helpers.permute_covM(P, clusters, visualize=True, print_nc=True)  # matches hueristic

np.savetxt(clusters_path, clusters, delimiter=",")
np.savetxt(nc_path, noise_cluster, delimiter=",")

### ANALYSIS ###
