import numpy as np
import imp

import map
imp.reload(map)

N = 10
M = 3

sigma = .5
beta1 = .5
beta2 = 5
rho = .6

bar_a = 30  # average number of gang members at centroid
bar_b = 30  # average number of violent randos per block
var_scale = .25  # standard deviation of trunnorm as a percentage of mean

p_war = .5

# eta_vals = [.01, .05, .1, .25, .5]
eta = .1
params = {"sigma":sigma, "eta":eta, "beta1":beta1, "beta2":beta2, "rho":rho, "bar_a":bar_a, "bar_b":bar_b, "var_scale":var_scale, "p_war":p_war}

Times = [25, 50, 75, 100, 250, 500, 1000, 5000, 10000]  # increase signal to noise ratio
nSims = 10
alphas = [.5, 1, 100, 10000]  # alpha trial values for nr_spect_clust

S = None

for T in Times:

    # eta = eta_vals[i]  # attack probabilities for randos (noise)
    # params = {"sigma":sigma, "eta":eta, "beta1":beta1, "beta2":beta2, "rho":rho, "bar_a":bar_a, "bar_b":bar_b, "var_scale":var_scale, "p_war":p_war}

    scores = None

    for j in range(nSims):

        scores_j = []

        row = 0

        # raw covariance matrix
        env = map.map(N, M, params)
        A = env.sim(T)
        covM = env.covMat(A)
        clusters = env.spect_clust(covM, M)
        s = env.score_cluster(env.gridIDs.ravel(), clusters, env.M+1)
        scores_j.append(s)
        row += 1

        # correlation matrix
        env = map.map(N, M, params)
        A = env.sim(T)
        covM = env.covMat(A)
        corM = env.covMtoCorM(covM)
        clusters = env.spect_clust(corM, M)
        s = env.score_cluster(env.gridIDs.ravel(), clusters, env.M+1)
        scores_j.append(s)
        row += 1

        # trace minimization (cov)
        env = map.map(N, M, params)
        A = env.sim(T)
        covM = env.covMat(A)
        Gamma_L = env.traceMin(covM)
        clusters = env.spect_clust(Gamma_L, M)
        s = env.score_cluster(env.gridIDs.ravel(), clusters, env.M+1)
        scores_j.append(s)
        row += 1

        # trace minimization (cor)
        env = map.map(N, M, params)
        A = env.sim(T)
        covM = env.covMat(A)
        Gamma_L = env.traceMin(covM)
        Gamma_Lcor = env.covMtoCorM(Gamma_L)
        clusters = env.spect_clust(Gamma_Lcor, M)
        s = env.score_cluster(env.gridIDs.ravel(), clusters, env.M+1)
        scores_j.append(s)
        row += 1

        # noise-robust (cov)
        for a in range(len(alphas)):
            env = map.map(N, M, params)
            A = env.sim(T)
            covM = env.covMat(A)
            clusters = env.nr_spect_clust(covM, M, alpha=alphas[a])
            s = env.score_cluster(env.gridIDs.ravel(), clusters, env.M+1)
            scores_j.append(s)
            row += 1

        # noise-robust (cor)
        for a in range(len(alphas)):
            env = map.map(N, M, params)
            A = env.sim(T)
            covM = env.covMat(A)
            corM = env.covMtoCorM(covM)
            clusters = env.nr_spect_clust(corM, M, alpha=alphas[a])
            s = env.score_cluster(env.gridIDs.ravel(), clusters, env.M+1)
            scores_j.append(s)
            row += 1

        if scores is None:
            scores = np.zeros((row, nSims))

        scores[:,j] = scores_j
        print(scores)

    if S is None:
        S = np.zeros((row, len(Times)))
    else:
        pass

    S[:,i] = np.mean(scores, axis=1)

np.savetxt("output/noiseSimResults.csv", S, delimiter=",")
