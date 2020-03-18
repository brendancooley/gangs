### SETUP ###

import numpy as np
import imp
import time
import os
import pyreadr
import matplotlib.pyplot as plt
import warnings

import helpers
imp.reload(helpers)

warnings.filterwarnings("ignore")

paths = pyreadr.read_r('params.RData') # also works for Rds

ts_period_path = paths['ts_period_path'].iloc[0, 0]  # shootings by tract, period is subset of dates to look at
geoids_path = paths['geoids_path'].iloc[0, 0]
tadjacency_path = paths['tadjacency_path'].iloc[0, 0]

runBaseline = False

# baseline destination paths
geoids_keep_path = paths['geoids_keep_path'].iloc[0, 0]
geoids_zero_path = paths['geoids_zero_path'].iloc[0, 0]
cov_mat_path = paths['cov_mat_path'].iloc[0, 0]
clusters_path = paths['clusters_path'].iloc[0, 0]
nc_path = paths['nc_path'].iloc[0, 0]
P_path = paths['P_path'].iloc[0, 0]
P_sorted_path = paths['P_sorted_path'].iloc[0, 0]
J_path = paths['J_path'].iloc[0, 0]
eig_path = paths['eig_path'].iloc[0, 0]
Bhat_path = paths["Bhat_path"].iloc[0, 0]

C = np.genfromtxt(tadjacency_path, delimiter=",")  # adjacency matrix
geoids = np.genfromtxt(geoids_path, delimiter=",")

runBootstrap = paths["runBootstrap"].iloc[0, 0]
L = int(paths["L"].iloc[0, 0])

# bootstrap destination paths
ts_period_bs_path = paths['ts_period_bs_path'].iloc[0, 0]
geoids_keep_bs_path = paths['geoids_keep_bs_path'].iloc[0, 0]
geoids_zero_bs_path = paths['geoids_zero_bs_path'].iloc[0, 0]
cov_mat_bs_path = paths['cov_mat_bs_path'].iloc[0, 0]
clusters_bs_path = paths['clusters_bs_path'].iloc[0, 0]
nc_bs_path = paths['nc_bs_path'].iloc[0, 0]
J_bs_path = paths['J_bs_path'].iloc[0, 0]
Bhat_bs_path = paths['Bhat_bs_path'].iloc[0, 0]

V = 3 # number of folds for cross validation

# bootstrap destination paths

### BASELINE ESTIMATES ###

counts = np.genfromtxt(ts_period_path, delimiter=",")

covM = helpers.covMat(counts, zero=False, cor=False)  # construct covariance matrix
# plt.imshow(covM, cmap="hot", interpolation="nearest")

P0 = covM - np.diag(np.diag(covM))
# plt.imshow(P0, cmap="hot", interpolation="nearest")

geoids_zero = geoids[np.argwhere(np.sum(P0, axis=0)==0)]  # district ids to drop from analysis (no covariance)
geoids_keep = geoids[np.argwhere(np.sum(P0, axis=0)!=0)]
np.savetxt(geoids_zero_path, geoids_zero)
np.savetxt(geoids_keep_path, geoids_keep)

P = P0[np.sum(P0, axis=0)!=0,:]
P = P[:,np.sum(P0, axis=0)!=0]
# plt.imshow(P, cmap="hot", interpolation="nearest")
np.savetxt(P_path, P, delimiter=',', fmt='%f')

# CLUSTERING #
M = helpers.est_J(P, V, S=25)
np.savetxt(J_path, np.array([M]), delimiter=",")

print("J estimation complete, " + str(M-1) + " gangs detected")

# return eigvals
lbda, U = np.linalg.eigh(P)
np.savetxt(eig_path, lbda, delimiter=",")

clusters, centroids = helpers.spect_clust(P, M, normalize=False, eig_plot=False)
theta = np.eye(M)[clusters]
X = centroids
Bhat = helpers.Bhat(P, X, M)  # estimate of connectivity matrix
# np.linalg.norm(Bhat, axis=1)
np.savetxt(Bhat_path, Bhat, delimiter=",")

noise_cluster = np.array([np.argmin(np.linalg.norm(Bhat, axis=1))])

np.savetxt(clusters_path, clusters, delimiter=",")
np.savetxt(nc_path, noise_cluster, delimiter=",")

P_sorted = helpers.permute_covM(P, clusters, nc=noise_cluster)
# plt.imshow(P_sorted, cmap="hot", interpolation="nearest")
np.savetxt(P_sorted_path, P_sorted, delimiter=',', fmt='%f')

### BOOTSTRAP ###

if runBootstrap == True:

    for i in range(1, L+1):

        print("bootstrap iteration " + str(i) + " starting")

        counts = np.genfromtxt(ts_period_bs_path + str(i) + ".csv", delimiter=",")

        covM = helpers.covMat(counts, zero=False, cor=False)
        np.savetxt(cov_mat_bs_path + str(i) + ".csv", covM, delimiter=",")
        P0 = covM - np.diag(np.diag(covM))

        geoids_zero = geoids[np.argwhere(np.sum(P0, axis=0)==0)]  # district ids to drop from analysis (no covariance)
        geoids_keep = geoids[np.argwhere(np.sum(P0, axis=0)!=0)]
        np.savetxt(geoids_zero_bs_path + str(i) + ".csv", geoids_zero)
        np.savetxt(geoids_keep_bs_path + str(i) + ".csv", geoids_keep)

        P = P0[np.sum(P0, axis=0)!=0,:]
        P = P[:,np.sum(P0, axis=0)!=0]
        
        M = helpers.est_J(P, V, S=25)
        np.savetxt(J_bs_path + str(i) + ".csv", np.array([M]), delimiter=",")

        print("J estimation complete, " + str(M-1) + " gangs detected")

        clusters, centroids = helpers.spect_clust(P, M, normalize=False, eig_plot=False)
        theta = np.eye(M)[clusters]
        X = centroids
        Bhat = helpers.Bhat(P, X, M)
        np.savetxt(Bhat_bs_path + str(i) + ".csv", Bhat, delimiter=",")

        noise_cluster = np.array([np.argmin(np.linalg.norm(Bhat, axis=1))])

        np.savetxt(clusters_bs_path + str(i) + ".csv", clusters, delimiter=",")
        np.savetxt(nc_bs_path + str(i) + ".csv", noise_cluster, delimiter=",")

        print("bootstrap iteration " + str(i) + " complete")
        print("-----")
