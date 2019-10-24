### SETUP ###

import numpy as np
import imp
import time
import os

import helpers
imp.reload(helpers)

gammaL_path = "output/gammaL.csv"

counts = np.genfromtxt("output/chi_dmatrix.csv", delimiter=",")
covM = helpers.covMat(counts, zero=True)  # construct covariance matrix

### TRACE MINIMIZATION ###
if not os.path.exists(gammaL_path):
    start_time = time.time()
    gammaL = helpers.traceMin(covM)
    print("trace minimization completed in %s seconds" % (time.time() - start_time))
    # (N=200): trace minimization completed in 2218.314126968384 seconds
    np.savetxt(gammaL_path, gammaL, delimiter=",")
