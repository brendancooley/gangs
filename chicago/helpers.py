import numpy as np
import mosek
from mosek.fusion import *
from sklearn import cluster
import matplotlib.pyplot as plt
from itertools import permutations

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

def spect_clust(covM, K, normalize=False, delta=None, C=None, eig_plot=False):
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
    lbda_K = np.flip(np.argsort(lbda))[0:K]
    U_k = U.T[lbda_K]  # NOTE: need to transpose eigenvectors
    if normalize is True:
        U_norm = np.linalg.norm(U_k, axis=0)
        U_k = U_k / U_norm

    if eig_plot is True:
        plt.plot(lbda[np.flip(np.argsort(lbda))], "r+")

    # cluster first M+1 eigenvectors
    km = cluster.k_means(U_k.transpose(), n_clusters=K)
    km_lab = km[1]
    km_centroids = km[0]

    return(km_lab, km_centroids)

def est_J(P, V):
    """Short summary.

    Parameters
    ----------
    P : matrix
        diagonal-less adjacency matrix
    V : int
        number of folds for cross-validation

    Returns
    -------
    type
        Description of returned object.

    """

    # TESTING
    V = 4
    P = np.genfromtxt('output/chi_ts_clust/all/P.csv', delimiter=",")
    P.shape
    S = 50

    N = P.shape[0]
    Kbar = 10

    mL = []

    for s in range(S):

        Loss = []
        fold_ids = fold_permutation(N, V)

        for k in np.arange(1, Kbar):

            loss_v = []

            for v in range(V):

                # k = 3
                v = 2

                fold_bin = np.copy(fold_ids) # zero if upper block, one otherwise
                fold_bin = np.where(fold_bin == v, 1, 0)
                Pp = rearrange_mat(P, fold_bin)
                rowN = N - np.sum(fold_bin)
                Ptilde = Pp[0:rowN,]
                Ptilde
                Pv = Pp[rowN:,rowN:]
                print(Pv.shape)
                Ptilde.shape
                # Ptilde_sq = Pp[0:rowN,0:rowN]
                # Ptilde_sq - Ptilde_sq.transpose()

                clusters, centroids = spect_clust(np.matmul(Ptilde.transpose(), Ptilde), k)

                theta = np.eye(k)[clusters]
                # np.sum(theta, axis=0)
                delta = np.diag(np.sum(theta, axis=0))
                theta_tilde = theta[0:rowN,]
                delta_tilde = np.diag(np.sum(theta_tilde, axis=0))
                if np.any(np.diag(delta_tilde) == 0):
                    print("singular delta_tilde matrix...proceeding to next fold...")
                    break
                # NOTE: possible that we get zeros in test set and can't invert
                # print(delta_tilde)
                Bhat = np.linalg.inv(delta_tilde) @ theta_tilde.transpose() @ Ptilde @ theta @ np.linalg.inv(delta)
                Bhat - Bhat.transpose()
                # TODO: not symmetric...why?

                # delta_tilde
                # delta

                P_hat = theta @ Bhat @ theta.transpose()
                P_hat = P_hat - np.diag(np.diag(P_hat))
                Pv_hat = P_hat[rowN:,rowN:]
                # print(Pv_hat)
                # Pv_hat.shape

                loss = np.linalg.norm(Pv - Pv_hat, ord="fro")  # Frobenius Norm
                loss_v.append(loss)

            Loss.append(np.mean(loss_v))

        minLoss = np.argmin(Loss)
        mL.append(minLoss)


def fold_permutation(N, V):
    """Short summary.

    Parameters
    ----------
    N : int
        number of rows of covariance matrix
    V : int
        number of folds for cross validation

    Returns
    -------
    array
        1d permuted vector of fold ids

    """

    folds = np.arange(V)
    rep = N // V
    rem = N % V
    fold_ids = np.repeat(folds, rep)
    for i in range(rem):
        fold_ids = np.append(fold_ids, np.random.choice(folds))
    fold_ids = np.random.permutation(fold_ids)

    return(fold_ids)

def permute_covM(covM, clusters, visualize=False, nc=0):
    """reorder covariance matrix to correspond to clustering output

    """

    counts = np.bincount(clusters)

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

    covMC = rearrange_mat(covM, clustersP)

    if visualize is True:
        plt.imshow(covMC, cmap="hot", interpolation="nearest")

    return(covMC)

def rearrange_mat(M, ids):
    """Short summary.

    Parameters
    ----------
    M : mat
        input matrix
    ids : array (1d)
        vector associating each row to a group

    Returns
    -------
    Mp
        permuted matrix

    """

    Mp = np.copy(M)
    counts = np.bincount(ids)

    p = []
    for i in range(len(counts)):
        for j in range(len(ids)):
            if ids[j] == i:
                p.append(j)
    Mp[:,:] = Mp[p,:]
    Mp[:,:] = Mp[:,p]

    return(Mp)

def Bhat_tilde(P, theta):



def Bhat(P, X, M):
    """estimate connectivity matrix B

    Parameters
    ----------
    P : type
        Description of parameter `P`.
    X : matrix K by K
        centroids from clustering output

    Returns
    -------
    matrix
        K times K connectivity matrix

    """

    lbda, U = np.linalg.eigh(P)
    lbda_K = np.flip(np.argsort(lbda))[0:M+1]
    Lbda = np.diag(lbda[lbda_K])

    return(np.matmul(np.matmul(X, Lbda), X.T))
