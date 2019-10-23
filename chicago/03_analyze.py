import numpy as np
import imp
import time

import helpers
imp.reload(helpers)

counts = np.genfromtxt("output/chi_dmatrix.csv", delimiter=",")
covM = helpers.covMat(counts, zero=True)

start_time = time.time()
gammaL = helpers.traceMin(covM)
print("trace minimization completed in %s seconds" % (time.time() - start_time))

np.savetxt("output/gammaL.csv", gammaL, delimiter=",")
