import numpy as np
import mosek
from mosek.fusion import *
from sklearn import cluster
import matplotlib.pyplot as plt

def covMat(A, zero=False, cor=False):
    """Short summary.

    Parameters
    ----------
    A : list
        N times T matrix of attack vectors stacked rowwise, each row denoting attacks per period in an unraveled district.
    zero : bool
        convert negative covariance entries to zero?
    cor : bool
        convert to correlation matrix?

    Returns
    -------
    matrix
        N times N matrix of covariances

    """
    if cor is True:
        # A[:,0] += .001  # add small value to first period to eliminate zeros
        covA = np.corrcoef(A)
    else:
        covA = np.cov(A)
        # correct for floating point problems with positive semi definiteness, see:
        # https://stackoverflow.com/questions/41515522/numpy-positive-semi-definite-warning

    # zero out negative values
    z = 0
    if zero is True:
        for i in range(len(covA)):
            for j in range(len(covA)):
                if covA[i, j] < 0:
                    covA[i, j] = 0
                    z += 1
        print(str(z) + " of " + str(covA.shape[0] ** 2) + " negative entries found and converted to zeros")
        min_eig = np.min(np.real(np.linalg.eigvals(covA)))
        if min_eig < 0:
            covA -= 10*min_eig * np.eye(*covA.shape)
            print("minimum eigenvalue: " + str(min_eig))
    else:
        min_eig = np.min(np.real(np.linalg.eigvals(covA)))
        if min_eig < 0:
            covA -= 10*min_eig * np.eye(*covA.shape)
            print("Floating point errors exist. Perturbing matrix...")

    return(covA)

def traceMin(covA):
    with Model("sdo1") as M:

        N = covA.shape[0]  # number of districts

        # target
        X = M.variable("X", Domain.inPSDCone(N))

        # coefficients
        C = Matrix.diag(N, 1)
        Aset = []
        bl = []
        bu = []
        for i in range(N):
            for j in range(i, N):
                a = Matrix.sparse(N, N, [i], [j], 1)
                Aset.append(a)  # a bunch of sparse matrices with ones to constrain each individual observation
                if (i != j):
                    # multiplying by two recovers alphas in TW framework
                    # mosek unhappy with this on my laptop though
                    bl.append(covA[i, j])
                    bu.append(covA[i, j])
                else:
                    bl.append(0)  # lower constraints are entries of covA except for diagonal
                    bu.append(covA[i, j])

        # setup objective
        M.objective(ObjectiveSense.Minimize, Expr.dot(C, X))

        # Constraints
        for i in range(len(Aset)):
            index = str(i)
            # print(Aset[i])
            M.constraint("cl"+index, Expr.dot(Aset[i], X), Domain.greaterThan(bl[i])) # lower
            M.constraint("cu"+index, Expr.dot(Aset[i], X), Domain.lessThan(bu[i])) # upper

        M.solve()

        gammaL = X.level().reshape(N, N)
    return(gammaL)

def C_bin_kernel(delta, C):
    out = np.zeros_like(C)
    for i in range(delta+1):
        Sd = np.linalg.matrix_power(C, i)
        out = out + Sd
    bin = np.where(out > 0, 1, 0)
    return(bin)

def spect_clust(covM, M, normalize=True, delta=None, C=None, eig_plot=False):
    """Conduct spectral clustering on trace-minimized covariance matrix

    TODO: k-medians implementation

    Parameters
    ----------
    gammaL : matrix self.N ** 2 ** 2
        Trace minimized covariance matrix.
    M : int
        Suspected number of groups
    delta : int
        Size of neighborhood for regionalization, if None then use fully connected gammaL

    Returns
    -------
    vector
        Cluster ids for each district.

    """
    G = covM
    if delta is not None:
        S = C_bin_kernel(delta, C)  # TODO: provide option for exp kernel
        G = S * covM

    # extract eigenvectors
    # w, v = np.linalg.eig(G)
    lbda, U = np.linalg.eigh(G) # NOTE: was getting complex eigenvalues using linalg.eig
    lbda_K = np.flip(np.argsort(lbda))[0:M+1]
    U_k = U.T[lbda_K]  # NOTE: need to transpose eigenvectors
    if normalize is True:
        U_norm = np.linalg.norm(U_k, axis=0)
        U_k = U_k / U_norm

    if eig_plot is True:
        plt.plot(lbda[np.flip(np.argsort(lbda))], "r+")

    # cluster first M+1 eigenvectors
    km = cluster.k_means(U_k.transpose(), n_clusters=M+1)
    km_lab = km[1]
    km_centroids = km[0]

    return(km_lab, km_centroids)

def permute_covM(covM, clusters, visualize=False, print_nc=False):
    """reorder covariance matrix to correspond to clustering output

    """

    counts = np.bincount(clusters)
    print(counts)

    # identify noise cluster (is this consistent with spectral clustering?)
    # NOTE: doesn't work when this assigns district to unique cluster (singletons)
    V = []
    for i in range(len(counts)):
        indices = np.where(clusters==i)[0]
        N = len(indices)
        blockM = np.copy(covM)[indices,:][:,indices]
        for j in range(blockM.shape[0]):
            blockM[j, j] = 0  # zero out diagonal
        if N != 1:
            v = np.sum(blockM) / (N ** 2 - N)
        else:
            v = np.sum(blockM) / N
        # TODO: normalizing by sqrt might be more principled...see Lei and Rinaldo
        V.append(v)
    nc = np.argmin(V)
    if print_nc is True:
        print("Cluster id " + str(nc) + " is the noise cluster.")

    # reassign noise cluster to last index
    clustersP = np.copy(clusters)
    M = np.max(clusters)
    for i in range(len(clustersP)):
        # flip noise cluster and last cluster
        if clustersP[i] == nc:
            clustersP[i] = M
        else:
            if clustersP[i] == M:
                clustersP[i] = nc

    covMC = np.copy(covM)
    p = []
    for i in range(len(counts)):
        for j in range(len(clustersP)):
            if clustersP[j] == i:
                p.append(j)
    covMC[:,:] = covMC[p,:]
    covMC[:,:] = covMC[:,p]

    if visualize is True:
        plt.imshow(covMC, cmap="hot", interpolation="nearest")

    return(covMC)
