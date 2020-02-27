import numpy as np
import imp

import gammaSim
imp.reload(gammaSim)

N = 50
J = 3
eta = .25
beta = 5
lbdaJ = 5
lbdaN = 10

gs = gammaSim.gammaSim(N, J, eta, beta, lbdaJ, lbdaN, pg=.75)
# gs.Jid
# gs.Jpop
# gs.Rpop
gs.simT(100)
# gs.A
gs.covMat()
gs.covA
np.trace(gs.covA)
np.all(np.linalg.eigvals(gs.covA) > 0)

# gs.covA
gs.traceMin() # turns into a hard problem quickly with larger N
gs.gammaL
np.trace(gs.gammaL)

# gammaL = Xout.reshape(gs.N, gs.N)  # GammaL
gammaD = gs.covA - gs.gammaL  # GammaD
np.trace(gs.covA)
np.trace(gs.gammaL)  # successfully reduces trace

gs.dbscan(1.5, minP=3)
gs.clstr_DBSCAN
# negative one are outlier points
# tends to be finding one cluster and a bunch of outlier points
    # probably because min_samples too large
    # even changing min_samples doesn't change this property though...super bizarre
    # with enough signal it seems to work ok, but not as robust as k-means to small signal to noise ratio

gs.kmeans(3)
gs.clstr_kmeans
gs.Jid
# k means gets about 80 percent right in baseline with pg = 1


# gs.Jpop
# gs.Rpop
# gs.A

# verify that this produces same matrix as Rmosek implementation
np.savetxt("covA.csv", gs.covA, delimiter=",")
# confirmed
