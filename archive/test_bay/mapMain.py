import numpy as np
import imp
import scipy.stats as stats
import matplotlib.pyplot as plt
from sklearn import cluster
import scipy
import itertools

import map

# N = 12
# M = 5
N = 10
M = 3
T = 100

sigma = .5
eta = .2  # attack probabilities for randos (noise)
beta1 = .5
beta2 = 5
rho = .6

bar_a = 30  # average number of gang members at centroid
bar_b = 30  # average number of violent randos per block
var_scale = .25  # standard deviation of trunnorm as a percentage of mean

p_war = .5

params = {"sigma":sigma, "eta":eta, "beta1":beta1, "beta2":beta2, "rho":rho, "bar_a":bar_a, "bar_b":bar_b, "var_scale":var_scale, "p_war":p_war}

imp.reload(map)
mapT = map.map(N, M, params)
plt.imshow(mapT.gridA, cmap="hot", interpolation="nearest")
# plt.imshow(mapT.gridR, cmap="hot", interpolation="nearest")

sim = mapT.sim(T)
sim_covM = mapT.covMat(sim)
sim_corM = mapT.covMtoCorM(sim_covM)

clusters = mapT.k_means(sim_corM, M)
np.reshape(clusters, (mapT.N, mapT.N))
mapT.score_cluster(mapT.gridIDs.ravel(), clusters, mapT.M+1)

Gamma_L = mapT.traceMin(sim_covM)
Gamma_Lcor = mapT.covMtoCorM(Gamma_L)
clusters = mapT.k_means(Gamma_Lcor, M)
np.reshape(clusters, (mapT.N, mapT.N))
mapT.score_cluster(mapT.gridIDs.ravel(), clusters, mapT.M+1)
# can find examples in which trace minimization helps a lot


clusters1 = mapT.spect_clust(sim_covM, M)
np.reshape(clusters1, (mapT.N, mapT.N))
mapT.score_cluster(mapT.gridIDs.ravel(), clusters1, mapT.M+1)  # using correlation matrix works nicely

sim_corM = mapT.covMat(sim, cor=True)
clusters2 = mapT.spect_clust(sim_corM, M)
np.reshape(clusters2, (mapT.N, mapT.N))
mapT.score_cluster(mapT.gridIDs.ravel(), clusters2, mapT.M+1)


# Gamma_L = mapT.traceMin(sim_covM)
clusters3 = mapT.spect_clust(Gamma_Lcor, M)
np.reshape(clusters3, (mapT.N, mapT.N))
mapT.score_cluster(mapT.gridIDs.ravel(), clusters3, mapT.M+1)
# but interesting that spectral clustering seems to perform better on Gamma_L rather than Gamma_Lcor
# spectral clustering of Gamma_L is most principled way to go I think

clusters4 = mapT.spect_clust(Y, M)
np.reshape(clusters4, (mapT.N, mapT.N))
mapT.score_cluster(mapT.gridIDs.ravel(), clusters4, mapT.M+1)



pmts = itertools.permutations(np.arange(0,4))
for p in pmts:
    print(p)

p[1]

for i in range(4):
    print(i)

# plt.imshow(sim_covM, cmap="hot", interpolation="nearest")


A = np.array([])
np.vstack([A, [1, 2, 3]])


np.trace(sim_covM)
Gamma_L = mapT.traceMin(sim_covM)
np.trace(Gamma_L)

# replot covariance matrix with permutation
clusters.reshape(mapT.N, mapT.N)
# trace minimization helps immensely in a setting with no noise...helps reduce within-district variance
# just converting to correlation matrix would also probably help...what's the logic here?


covMP = mapT.permute_covM(Gamma_L, clusters)
# NOTE: blockM seems to be working fine...problem comes somewhere in permuting the whole matrix


plt.imshow(Gamma_L, cmap="hot", interpolation="nearest")
plt.imshow(covMP, cmap="hot", interpolation="nearest")


list(itertools.permutations(np.array([0,1,2])))




test = np.copy(Gamma_L)
p = np.flip(np.arange(0, len(clusters)))
plt.imshow(test, cmap="hot", interpolation="nearest")
test[:,:] = test[p,:]
plt.imshow(test, cmap="hot", interpolation="nearest")
test[:,:] = test[:,p]
plt.imshow(test, cmap="hot", interpolation="nearest")
# test = np.array([[1, 2, 3], [4, 5, 6], [7, 8, 9]])
# test[np.ix_([2, 1, 0],[2, 1, 0])]



# trace minimization
np.trace(sim_covM)
# np.trace(Gamma_L)
# plt.imshow(Gamma_L, cmap="hot", interpolation="nearest")



np.trace(Y)  # compare trace to traceMin...not comparable because we've converted to distance matrix
plt.imshow(Y, cmap="hot", interpolation="nearest")

mapT.spect_clust(sim_covM, M).reshape((mapT.N, mapT.N))  # raw matrix
mapT.spect_clust(Y, M).reshape((mapT.N, mapT.N))  # Yuan matrix
mapT.spect_clust(Gamma_L, M).reshape((mapT.N, mapT.N))  # trace-minimized matrix





np.random.binomial([10,10], .5)


# actually works very well at finding noise cluster, so long as alpha > 1 or so
# doesn't require trace minimization
# what do eigengaps look like?
# plot permuted heatmaps to see if we can see war intensities

# compare this to GammaL
Gamma_L = mapT.traceMin(sim_covM)
mapT.spect_clust(Gamma_L, M).reshape((mapT.N, mapT.N))
mapT.spect_clust(sim_covM, M).reshape((mapT.N, mapT.N))
# not actually a ton of improvement when T large, try with smaller T?
# struggling to find a case where noise robust method delivers result that doesn't emerge from simply clustering covariance matrix...
    # you can always see the eigengaps in the cov matrix right away when good clustering is possible
    # actually can find cases where noise-robust version performs worse than just clustering cov matrix
    # trace minimization does seem to emphasize the eigengap somewhat...
    # but getting the noise cluster is as simple as setting the number of clusters to M+1


# W = np.diag(np.ones(sim_covM.shape[0])) - ngL

plt.imshow(Y, cmap="hot", interpolation="nearest")





np.sum(, axis=1)



np.trace(sim_covM)

np.sum(ngL, axis=1)


sim_covM.shape[0]

Gamma_L = mapT.traceMin(sim_covM)
np.trace(Gamma_L)
plt.imshow(Gamma_L, cmap="hot", interpolation="nearest")

# check positive definiteness
w, v = np.linalg.eig(Gamma_L)
w > 0

S = mapT.C_bin_kernel(4)
Gamma_LS = S * Gamma_L
plt.imshow(Gamma_LS, cmap="hot", interpolation="nearest")
w, v = np.linalg.eig(Gamma_L)
w > 0

Dvec = np.sum(Gamma_LS, axis=1)
# Dvec = np.where(Dvec < 0, 1, Dvec)  # replace negative vals with small value
D = np.diag(Dvec)

LS = D - Gamma_LS  # graph Laplacian
# jitter to ensure positive definiteness
min_eig = np.min(np.real(np.linalg.eigvals(LS)))
LS -= 10*min_eig * np.eye(*LS.shape)
w, v = np.linalg.eig(LS)
w > 0


Dinv = np.diag(Dvec ** (-.5))
L_norm = Dinv @ L @ Dinv # normalized
w, v = np.linalg.eig(L_norm)
w > 0
# Gamma_LS_norm = Dinv @ Gamma_LS @ Dinv



plt.imshow(Gamma_L, cmap="hot", interpolation="nearest")
# think I need some sort of normalization...
# shouldn't have negative eigenvalues...

w, v = np.linalg.eig(Gamma_LS) # NOTE: need to flip output eigenvectors
plt.plot(np.sort(w), 'r+') # eigengaps showing up nicely
kw = np.flip(np.argsort(w))[0:M+1]
kv = v.T[kw]
plt.plot(kv[2], 'r+')
# NOTE: we want largest eigenvalues since we're working with Gamma_L

km = cluster.k_means(kv.transpose(), n_clusters=M+1)
km_lab = km[1]
km_labM = np.reshape(km_lab, (mapT.N, mapT.N))
plt.imshow(km_labM, interpolation="nearest")
plt.imshow(mapT.gridA, cmap="hot", interpolation="nearest")
# using M + 1 clusters nails it


# actually do quite well even without S, but geography does seem to improve things a bit
w, v = np.linalg.eig(Gamma_L) # NOTE: need to flip output eigenvectors
plt.plot(np.sort(w), 'r+') # eigengaps showing up nicely
kw = np.flip(np.argsort(w))[0:M+1]
kv = v.T[kw]
plt.plot(kv[2], 'r+')


km = cluster.k_means(kv.transpose(), n_clusters=M+1)
km_lab = km[1]
km_labM = np.reshape(km_lab, (mapT.N, mapT.N))
plt.imshow(km_labM, interpolation="nearest")

# TODO: how to deal with noise points?



d = np.random.normal(loc=1, scale=.1, size=10)
D = np.diag(d)
test = scipy.linalg.fractional_matrix_power(D, -.5)
test2 = np.diag(d ** -.5)

















# get same result from just clustering Gamma_L
Gamma_LS[11*12+1, ]
ktest = cluster.k_means(Gamma_LS, n_clusters=M)
ktest_lab = ktest[1]
ktest_labM = np.reshape(ktest_lab, (mapT.N, mapT.N))
plt.imshow(ktest_labM, interpolation="nearest")







D = np.diag(np.sum(Gamma_L, axis=1))
L = D - Gamma_L

D_norm = D ** (-.5) @ L @ D ** ()




sim_covM.shape
mapT.C[1, ]
test = mapT.C @ mapT.C
test / 2 + mapT.C + np.diag(np.ones(mapT.N**2))

mapT.alpha
plt.imshow(mapT.gridA, cmap="hot", interpolation="nearest")

S = mapT.rand_S(.5)
mapT.S_to_dict(S)


Q = mapT.Q(S)
plt.imshow(Q[0], cmap="hot", interpolation="nearest")

# plt.imshow(Q[0], cmap='hot', interpolation='nearest')
A = mapT.simT(S)

A.shape
covA = mapT.covMat(A)
covA
# check semi definiteness
np.all(np.linalg.eigvals(covA) > 0)

np.trace(covA)

tmin = mapT.traceMin(covA)
np.trace(tmin)
plt.imshow(tmin, cmap="hot", interpolation="nearest")



np.eye(*covA.shape)
d = []
for i in range(mapT.N**2):
    d.append(covA[i, i])


mapT.N**2
test = mapT.gridR
A = np.zeros((100, T))

A[:, 1]

for i in range(2, 3):
    print(i)


np.random.binomial(range(10), .5)
eJ = np.random.beta(2, 5)
eM = np.random.binomial(range(100), eJ)

a = mapT.gridA
plt.imshow(a, cmap='hot', interpolation='nearest')

mapT.gridR

mapT.gridBase
mapT.neighbors((5,5))


np.round([4.1, 8.9])


stats.truncnorm.rvs(-1/.25,1/.25, scale=.25, size=100)

stats.truncnorm.pdf(x, -1, 1)

def neighbors(coords):
    """Short summary.

    Parameters
    ----------
    coords : type
        Description of parameter `coords`.

    Returns
    -------
    type
        Description of returned object.

    """

    x = coords[0]
    y = coords[1]

    neighbors = [(x-1,y), (x+1,y), (x,y-1), (x,y+1)]

    return(neighbors)

neighbors_a = neighbors((5,5))
