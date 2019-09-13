import numpy as np
import imp

import map
imp.reload(map)

N = 10
M = 3
T = 1000

sigma = .5
beta1 = .5
beta2 = 5
rho = .6

bar_a = 30  # average number of gang members at centroid
bar_b = 30  # average number of violent randos per block
var_scale = .25  # standard deviation of trunnorm as a percentage of mean

p_war = .5

eta_vals = [.01, .05, .1, .25, .5]

nSims = 10
alphas = [.5, 1, 100, 10000]  # alpha trial values for nr_spect_clust

for i in range(len(eta_vals)):

    eta = eta_vals[i]  # attack probabilities for randos (noise)
    params = {"sigma":sigma, "eta":eta, "beta1":beta1, "beta2":beta2, "rho":rho, "bar_a":bar_a, "bar_b":bar_b, "var_scale":var_scale, "p_war":p_war}

    S = np.zeros((3+len(alphas), len(eta_vals)))
    scores = np.zeros((3+len(alphas), nSims))

    for j in range(nSims):

        # raw covariance matrix
        env = map.map(N, M, params)
        A = env.sim(T)
        covM = env.covMat(A)
        clusters = env.spect_clust(covM, M)
        s = env.score_cluster(env.gridIDs.ravel(), clusters, env.M+1)
        scores[0, j] = s

        # correlation matrix
        env = map.map(N, M, params)
        A = env.sim(T)
        covM = env.covMat(A, cor=True)
        clusters = env.spect_clust(covM, M)
        s = env.score_cluster(env.gridIDs.ravel(), clusters, env.M+1)
        scores[1, j] = s

        # trace minimization
        env = map.map(N, M, params)
        A = env.sim(T)
        covM = env.covMat(A)
        Gamma_L = env.traceMin(covM)
        clusters = env.spect_clust(Gamma_L, M)
        s = env.score_cluster(env.gridIDs.ravel(), clusters, env.M+1)
        scores[2, j] = s

        # noise-robust
        for a in range(len(alphas)):
            env = map.map(N, M, params)
            A = env.sim(T)
            covM = env.covMat(A)
            clusters = env.nr_spect_clust(covM, M, alpha=alphas[a])
            s = env.score_cluster(env.gridIDs.ravel(), clusters, env.M+1)
            scores[3+a, j] = s

    S[:,i] = np.mean(scores, axis=1)

np.savetxt("noiseSimResults.csv", S, delimiter=",")
