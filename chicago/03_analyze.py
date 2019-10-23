import numpy as np
import imp

import helpers
imp.reload(helpers)

counts = np.genfromtxt("output/chi_dmatrix.csv", delimiter=",")
covM = helpers.covMat(counts, zero=True)
gammaL = helpers.traceMin(covM)

np.savetxt("output/gammaL.csv", gammaL, delimiter=",")
