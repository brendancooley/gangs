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
    K : int
        Suspected number of clusters
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
    # print(U_k)
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

def est_J(P, V, S=50):
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
    # V = 3
    # P = np.genfromtxt('output/chi_ts_clust/all/P.csv', delimiter=",")
    # S = 50

    N = P.shape[0]
    Kbar = 10

    Jvec = []
    # NOTE: another way to do this is to output the first time we don't get a decrease in loss...argument being that rest of vector is noise
        # this is consistent with results in Chen and Lei, they only provide guarantees against under estimation
    # np.median(mL)

    for s in range(S):

        Loss = []
        fold_ids = fold_permutation(N, V)

        for k in np.arange(1, Kbar):

            loss_v = []
            # k = 3

            for v in range(V):

                fold_bin = np.copy(fold_ids) # zero if upper block, one otherwise
                # print(fold_bin)
                fold_bin = np.where(fold_bin == v, 1, 0)
                Pp = rearrange_mat(P, fold_bin)
                rowN = N - np.sum(fold_bin)
                Ptilde = Pp[0:rowN,]
                # Ptilde.shape
                Pv = Pp[rowN:,rowN:]
                # Pv.shape
                Ptilde_sq = Pp[0:rowN,0:rowN]

                clusters, centroids = spect_clust(np.matmul(Ptilde.transpose(), Ptilde), k)
                # u, s, vh = np.linalg.svd(Ptilde)
                # vh[0:k,]
                # NOTE: right singular vectors match up
                theta = np.eye(k)[clusters]

                # np.sum(theta, axis=1)
                # np.sum(theta, axis=0)
                delta = np.diag(np.sum(theta, axis=0))
                theta_tilde = theta[0:rowN,]
                delta_tilde = np.diag(np.sum(theta_tilde, axis=0))
                # if np.any(np.diag(delta_tilde) == 0):
                #     print("singular delta_tilde matrix...proceeding to next fold...")
                #     break
                # NOTE: possible that we get zeros in test set and can't invert
                # print(delta_tilde)
                # Bhat = np.linalg.inv(delta_tilde) @ theta_tilde.transpose() @ Ptilde @ theta @ np.linalg.inv(delta)
                Bhat = Bhat2(Ptilde, theta, rowN)
                # print(Bhat)
                # TODO: not symmetric...why?
                    # I think this is because we have zeros on the diagonal in Atilde
                    # same problem with my estimates and what comes out of Chen and Lei estimator. Problem with thetas?
                    # Solution: this estimator implies asymmetry but is consistent. Need to do as Lei code does and just do upper triangular loop

                P_hat = theta @ Bhat @ theta.transpose()
                if np.any(np.isnan(Bhat)):
                    print("warning: nan in Bhat")
                P_hat = P_hat - np.diag(np.diag(P_hat))
                Pv_hat = P_hat[rowN:,rowN:]
                # print(Pv_hat)
                # Pv_hat.shape

                # loss = 0
                # for i in range(Pv.shape[0]):
                #     for j in range(Pv.shape[1]):
                #         loss += (Pv[i, j] - Pv_hat[i, j]) ** 2

                loss = np.linalg.norm(Pv - Pv_hat, ord="fro")  # Frobenius Norm
                loss_v.append(loss)


            Loss.append(np.mean(loss_v))

        print("Loss vec " + str(s) + ":")
        print(Loss)
        Ldelta = Loss - np.append(Loss[1:], 0)
        # len(np.where(np.array([1, 0, 0]) == 2)[0])
        if len(np.where(Ldelta < 0)[0]) > 0:
            # np.where(np.array([1, 0, 0]) == 1)
            Jhat = np.min(np.where(Ldelta < 0)[0]) + 1
            Jvec.append(Jhat)
        else:
            Jvec.append(Kbar)

    Jhat_counts = np.bincount(Jvec)
    print("Jhat_counts:")
    print(Jhat_counts)
    out = np.argmax(Jhat_counts) + 1

    return(out)


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

def Bhat2(Ptilde, theta, rowN):
    """Implement B estimator in Chen and Lei

    Parameters
    ----------
    Ptilde : type
        Description of parameter `Ptilde`.
    theta : type
        Description of parameter `theta`.
    rowN : type
        Description of parameter `rowN`.

    Returns
    -------
    type
        Description of returned object.

    """

    # TESTING
    theta_1 = theta[0:rowN,]
    theta_2 = theta[rowN:,]

    P1 = Ptilde[:,0:rowN]
    P2 = Ptilde[:,rowN:]

    K = theta_1.shape[1]
    B = np.zeros((K, K))

    for i in range(K):
        i_ids1 = theta_1[:,i]
        n_i1 = np.sum(i_ids1)
        for j in range(K):

            if j <= i:

                j_ids1 = theta_1[:,j]
                j_ids2 = theta_2[:,j]
                n_j1 = np.sum(j_ids1)
                n_j2 = np.sum(j_ids2)

                P_ij1 = P1[i_ids1==1,:]
                P_ij1 = P_ij1[:,j_ids1==1]
                P_ij1_tri = np.triu(P_ij1)
                P_ij2 = P2[i_ids1==1,:]
                P_ij2 = P_ij2[:,j_ids2==1]

                if i == j:
                    b_sum = np.sum(P_ij1_tri)
                    b_sum += np.sum(P_ij2)
                    B[i, j] = b_sum / ( (n_i1 - 1) * n_i1 / 2 + n_i1 * n_j2 )
                else:
                    b_sum = np.sum(P_ij1)
                    b_sum += np.sum(P_ij2)
                    B[i, j] = b_sum / ( n_i1 * (n_j1 + n_j2) )
                    B[j, i] = B[i, j]

    return(B)







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
    lbda_K = np.flip(np.argsort(lbda))[0:M]
    Lbda = np.diag(lbda[lbda_K])

    return(np.matmul(np.matmul(X, Lbda), X.T))
