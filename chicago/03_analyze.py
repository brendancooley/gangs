### SETUP ###

import numpy as np
import imp
import time
import os
import pyreadr

import helpers
imp.reload(helpers)

paths = pyreadr.read_r('params.RData') # also works for Rds

chi_dmatrix_path = paths['chi_dmatrix_path'].iloc[0, 0]
gammaL_path = paths['gammaL_path'].iloc[0, 0]
clusters_path = paths['clusters_path'].iloc[0, 0]
chi_dadjacency_path = paths['chi_dadjacency_path'].iloc[0, 0]

C = np.genfromtxt(chi_dadjacency_path, delimiter=",")  # adjacency matrix

counts = np.genfromtxt(chi_dmatrix_path, delimiter=",")
covM = helpers.covMat(counts, zero=True)  # construct covariance matrix

### TRACE MINIMIZATION ###
if not os.path.exists(gammaL_path):
    start_time = time.time()
    gammaL = helpers.traceMin(covM)
    print("trace minimization completed in %s seconds" % (time.time() - start_time))
    # (N=200): trace minimization completed in 2218.314126968384 seconds
    np.savetxt(gammaL_path, gammaL, delimiter=",")

# diagnostics
gammaL = np.genfromtxt(gammaL_path, delimiter=",")
np.trace(covM)
np.trace(gammaL)

### CLUSTERING ###
M = 2
# clusters = helpers.spect_clust(gammaL, M, delta=1, C=C, eig_plot=True)  # regionalization version
clusters = helpers.spect_clust(gammaL, M, eig_plot=True)

np.savetxt(clusters_path, clusters, delimiter=",")


### ANALYSIS ###

helpers.permute_covM(gammaL, clusters, visualize=True, print_nc=True)
