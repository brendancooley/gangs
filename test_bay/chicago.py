import numpy as np
import imp
import scipy.stats as stats
import matplotlib.pyplot as plt
from sklearn import cluster
import scipy

import timeit
import time
import csv

import map

M = 5
T = 100

sigma = .5
eta = .3
beta = 5
rho = .5

bar_a = 60  # average number of gang members at centroid
bar_b = 60  # average number of violent randos per block
var_scale = .25  # standard deviation of trunnorm as a percentage of mean

p_war = .5

params = {"sigma":sigma, "eta":eta, "beta":beta, "rho":rho, "bar_a":bar_a, "bar_b":bar_b, "var_scale":var_scale, "p_war":p_war}

### RUNTIME ANALYSIS ###

def traceMin_runtime(mapT, N_vec, M, T, params, time):
    """Short summary.

    Parameters
    ----------
    mapT : type
        Description of parameter `mapT`.
    N_vec : vector
        i ** 2 = total number of districts
    M : type
        Description of parameter `M`.
    T : type
        Description of parameter `T`.
    params : type
        Description of parameter `params`.

    Returns
    -------
    type
        Description of returned object.

    """

    n_out = []
    t_out = []
    for i in N_vec:
        print(i)
        mapT = map.map(i, M, T, params)
        sim = mapT.sim(15)
        covM = mapT.covMat(sim)
        start_time = time.time()
        covMtm = mapT.traceMin(covM)
        t = time.time() - start_time
        t_out.append(t)
        n_out.append(covM.shape[0])
    return( np.array([np.array(n_out), np.array(t_out)]) )

n_test = [6, 8, 10, 12]
test = traceMin_runtime(map, n_test, M, T, params, time)

plt.scatter(test[0,:], test[1,:])
plt.show()

z = np.polyfit(test[0,:], np.log(test[1,:]), 1)
f = np.poly1d(z)

np.exp(f(1319)) / 60 / 60 / 24  # runtime in days...yikes


### CHI DATA STARTS HERE ###

chi = np.genfromtxt("chi_matrix.csv", delimiter=',', skip_header=1)
ids = np.genfromtxt("chi_ids.csv", delimiter=',', skip_header=1)
ids.shape


imp.reload(map)
mapT = map.map(N, M, T, params)

chiCM = mapT.covMat(chi)
plt.imshow(chiCM, cmap="hot", interpolation="nearest")

# for i in range(chiCM.shape[0]):
#     if chiCM[2, i] != 0:
#         print(chiCM[2, i])
np.trace(chiCM)

start_time = time.time()
chiGammaL = mapT.traceMin(chiCM)
print("--- %s seconds ---" % (time.time() - start_time))

np.trace(chiGammaL)
plt.imshow(chiGammaL)

# extract eigenvectors
w, v = np.linalg.eigh(chiGammaL)
kw = np.flip(np.argsort(w))[0:M+1]
kv = v.T[kw]  # NOTE: need to transpose eigenvectors

plt.plot(np.flip(np.sort(w)), 'r+')
print(w[np.flip(np.argsort(w))[0:10]])

min_eig = np.min(np.real(np.linalg.eigvals(chiGammaL)))

Mchi = 5

chi_clusters = mapT.spect_clust(chiGammaL, Mchi)
chiGammaL.shape
chi_clusters
# chi_clustersCM = mapT.spect_clust(chiCM, 10)
# chi_clustersCM


# export
ids = ids.astype(int)
with open("chi_cluster_ids.csv", "w") as csvfile:
    writer = csv.writer(csvfile, delimiter=",")
    for i in range(len(ids)):
        print(i)
        writer.writerow([ids[i], chi_clusters[i]])
