import numpy as np
import random
import scipy.stats as stats
import mosek
from mosek.fusion import *
from sklearn import cluster
import timeit
import time

class map:

    def __init__(self, N, M, T, params):
        """Short summary.

        Parameters
        ----------
        N : int
            sqrt(N) = total number of territories
        M : int
            number of gangs
        T : int
        params : dict

        Returns
        -------
        type
            Description of returned object.

        """

        self.N = N  # number of territories
        self.M = M  # number of groups
        self.T = T  # number of periods in macro period

        # Parameters
        self.sigma = params["sigma"]  # elasticity of substitution violence production function
        self.eta = params["eta"]  # probability of random killing
        self.beta = params["beta"]  # second parameter of beta dist, governs group attack probabilities
        self.rho = params["rho"]
        self.bar_a = params["bar_a"]
        self.bar_b = params["bar_b"]
        self.var_scale = params["var_scale"]
        self.p_war = params["p_war"]

        self.gridBase = np.zeros(N**2)
        self.gridBase = np.reshape(self.gridBase, (self.N, self.N))

        self.coords, self.C =  self.grid_to_C()

        self.gridA = np.copy(self.gridBase)  # total population on each cell

        self.gridsM = []
        self.aM = np.zeros(M)

        for i in range(self.M):

            grid_i = np.copy(self.gridBase)

            f = set() # store tuples id-ing cells that have been filled

            # draw centroid
            weights = self.Tweights()

            c_idx = np.random.choice(range(len(self.coords)), size=1, p=weights)[0]
            centroid = self.coords[c_idx]

            active_cell = centroid
            sd = self.bar_a * self.var_scale
            draw = stats.truncnorm.rvs(0, np.inf, loc=self.bar_a, scale=sd)
            grid_i[centroid[0], centroid[1]] = np.floor(draw)
            self.gridA[centroid[0], centroid[1]] += np.floor(draw)  # update master grid
            f.add(active_cell)

            while len(f) < self.N**2:
                neighbors_a = self.neighbors(active_cell)
                candidates = []
                for n in neighbors_a:
                    if 0 <= n[0] < N:
                        if 0 <= n[1] < N:  # check bounds
                            if n not in f:
                                neighbors_n = self.neighbors(n) # get neighbors of n
                                alphas_n = []
                                for m in neighbors_n:
                                    if m in f:
                                        alphas_n.append(grid_i[m[0], m[1]])
                                mean_n = np.mean(alphas_n) * self.rho
                                if mean_n==0:
                                    mean_n = .01
                                sd_n = mean_n * self.var_scale
                                draw = stats.truncnorm.rvs(0, np.inf, loc=mean_n, scale=sd_n)
                                grid_i[n[0], n[1]] = np.floor(draw)  # update group grid
                                self.gridA[n[0], n[1]] += np.floor(draw)  # update master grid
                                self.aM[i] += np.floor(draw)  # update group total strength
                                f.add(n)
                            candidates.append(n)
                            active_cell = random.choice(candidates)

            self.gridsM.append(grid_i)

        # populate randos
        sd_r = self.bar_b * self.var_scale
        gridRvec = stats.truncnorm.rvs(0, np.inf, loc=self.bar_b, scale=sd_r, size=N**2)
        self.gridR = np.reshape(np.floor(gridRvec), (self.N, self.N)).astype(int)

        # cd parameter
        self.alpha = (np.mean(self.gridA) / self.M) / np.mean(self.aM)

    def neighbors(self, coords):
        """Short summary.

        Parameters
        ----------
        coords : tuple
            coordinates of block you would like to return neighbors for

        Returns
        -------
        list of tuples (length 4)
            neighbors

        """

        x = coords[0]
        y = coords[1]

        neighbors = [(x-1,y), (x+1,y), (x,y-1), (x,y+1)]

        return(neighbors)

    def grid_to_C(self):
        """Generate contiguity matrix and vector mapping ids to tuples storing coordinates of all territories

        Returns
        -------
        list, matrix
            List length N**2, tuples with coordinates of territorial grid
            Matrix length N**2 times N**2 indicating contiguity of each cell with all others

        """

        tups = []
        C = np.reshape(np.zeros((self.N**2)**2), (self.N**2, self.N**2))

        for i in range(self.N):
            for j in range(self.N):
                tups.append((i, j))

        c = 0
        for i in range(self.N):
            for j in range(self.N):
                neighbors = self.neighbors((i, j))
                for k in neighbors:
                    if 0 <= k[0] < self.N:
                        if 0 <= k[1] < self.N:  # check bounds
                            idx = tups.index(k)
                            C[c, idx] = 1
                c += 1

        return(tups, C)

    def C_exp_kernel(self, delta):
        """Create exponential kernel of degree delta from contiguity matrix (see Yuan et al)

        Parameters
        ----------
        delta : int
            Degree of kernel

        Returns
        -------
        matrix
            Matrix length N**2 times N**2 kernel

        """

        out = np.zeros_like(self.C)
        for i in range(delta+1):
            Sd = np.linalg.matrix_power(self.C, i) / np.math.factorial(delta)
            out = out + Sd
        return(out)

    def C_bin_kernel(self, delta):
        out = np.zeros_like(self.C)
        for i in range(delta+1):
            Sd = np.linalg.matrix_power(self.C, i)
            out = out + Sd
        bin = np.where(out > 0, 1, 0)
        return(bin)

    def Tweights(self):
        """weights for sampling centroids

        Returns
        -------
        vector
            Length N**2, entry i, j = 1 / gridA[i, j]

        """
        gridA = self.gridA + 1
        weights = 1 / gridA
        return(weights.ravel() / np.sum(weights))

    def rand_S(self, pWar):
        """Draw random wars each with prbability Pwar and return symmetric war matrix

        Parameters
        ----------
        pWar : scalar
            \in [0,1]

        Returns
        -------
        matrix
            M times M symmetric matrix of active wars

        """
        S = np.zeros((self.M, self.M))
        for i in range(self.M):
            for j in range(i+1, self.M):
                draw = np.random.uniform()
                if draw < pWar:
                    S[i, j] = 1
                    S[j, i] = 1
        return(S)

    def simT(self, S):
        """Simulate a "macro-period" of T periods

        Parameters
        ----------
        S : matrix
            M times M symmetric matrix of active wars

        Returns
        -------
        list
            Length T list of attack vectors, corresponding to unraveled grid

        """

        A = np.zeros((self.N**2, self.T))
        Q = self.Q(S)

        for t in range(self.T):
            a = np.zeros(self.N**2)
            for q in Q:
                eJ = np.random.beta(2, self.beta) # draw q-specific attack probabilities
                eM = np.random.binomial(q.ravel(), eJ)
                a += eM
            eR = np.random.binomial(self.gridR.ravel(), self.eta)
            a += eR
            A[:, t] = a

        return(A)

    def sim(self, P):

        A = np.zeros((self.N**2, self.T*P))
        for p in range(P):  # for each macro-period
            # draw wars
            S = self.rand_S(self.p_war)
            A_p = self.simT(S)
            A[:,self.T*p:self.T*(p+1)] = A_p

        return(A)

    def traceMin(self, covA):
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


    def Q(self, S):
        """Violence potential function.

        Parameters
        ----------
        S : matrix
            M times M symmetric matrix of active wars

        Returns
        -------
        list
            list of N times N matrices of organized violence potential for each war

        """

        Q = []
        Sdict = self.S_to_dict(S)

        for s in Sdict.keys():
            q = np.zeros_like(self.gridA)
            war = Sdict[s]
            m = war[0]
            n = war[1]
            a_m = self.aM[m]
            a_n = self.aM[n]
            for i in range(len(self.coords)):
                coord = self.coords[i]
                a_im = self.gridsM[m][coord[0], coord[1]]
                a_in = self.gridsM[n][coord[0], coord[1]]
                a0 = np.array([a_im, a_n])
                a1 = np.array([a_in, a_m])
                q[coord[0], coord[1]] += self.cd(a0, self.alpha)
                q[coord[0], coord[1]] += self.cd(a1, self.alpha)
            Q.append(np.floor(q).astype(int))
        return(Q)

    def S_to_dict(self, S):
        """Convert war matrix to dictionary mapping unique wars to identities of belligerents

        Parameters
        ----------
        S : matrix
            M times M symmetric matrix of active wars

        Returns
        -------
        dict
            Dictionary mapping war ids to belligerent ids

        """
        Sdict = dict()
        c = 0
        for i in range(S.shape[0]):
            for j in range(i+1, S.shape[0]):
                if S[i, j] == 1:
                    Sdict[c] = (i, j)
                    c += 1
        return(Sdict)

    def cd(self, a, alpha):
        """

        Parameters
        ----------
        a : list
            2d list of vpf inputs
        alpha : scalar
            cd shares of local strength, total enemy strength

        Returns
        -------
        scalar
            violence potential

        """
        return(a[0]**(1-self.alpha) * a[1]**self.alpha)

    def sig_norm(self, x, sigma):
        """

        Parameters
        ----------
        x : 1d numpy array
        sigma : positive scalar

        Returns
        -------
        scalar
            "sigma norm" of vector x

        """
        return(np.sum(x**sigma)**(1/sigma))

    def covMat(self, A, zero=True):
        """Short summary.

        Parameters
        ----------
        A : list
            N times T matrix of attack vectors stacked rowwise, each row denoting attacks per period in an unraveled district.
        zero : bool
            convert negative covariance entries to zero?

        Returns
        -------
        matrix
            N times N matrix of covariances

        """
        covA = np.cov(A)
        # correct for floating point problems with positive semi definiteness, see:
        # https://stackoverflow.com/questions/41515522/numpy-positive-semi-definite-warning
        min_eig = np.min(np.real(np.linalg.eigvals(covA)))
        if min_eig < 0:
            covA -= 10*min_eig * np.eye(*covA.shape)
        # zero out negative covariances
        if zero is True:
            for i in range(len(covA)):
                for j in range(len(covA)):
                    if covA[i, j] < 0:
                        covA[i, j] = 0
        return(covA)

    def L(self, W):
        """Short summary.

        Parameters
        ----------
        W : matrix
            N times N matrix of weights (covariances).

        Returns
        -------
        matrix (Laplacian)
            N times N matrix of distances

        """

        return(np.diag(np.ones(W.shape[0])) - W)

    def ngL(self, W):
        """Compute normalized graph Laplacian given weighting matrix

        Parameters
        ----------
        W : matrix
            N times N matrix of weights (covariances).

        Returns
        -------
        matrix (normalized Laplacian)
            N times N matrix of normalized distances

        """

        I = np.diag(np.ones(W.shape[0]))
        L = I - W
        D = np.sum(W, axis=1)

        ngL = np.matmul(np.matmul(np.diag(D ** (-1/2)), L), np.diag(D ** (-1/2)))

        return(ngL)

    def Y(self, Kr, alpha=1000):

        int = np.diag(np.ones(Kr.shape[0])) + alpha * np.linalg.inv(Kr)
        out = np.linalg.inv(int)

        return(out)

    def spect_clust(self, gammaL, M, delta=None):
        """Conduct spectral clustering on trace-minimized covariance matrix

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
        G = gammaL
        if delta is not None:
            S = mapT.C_bin_kernel(delta)  # TODO: provide option for exp kernel
            G = S * Gamma_L

        # extract eigenvectors
        # w, v = np.linalg.eig(G)
        w, v = np.linalg.eigh(G) # NOTE: was getting complex eigenvalues using linalg.eig
        kw = np.flip(np.argsort(w))[0:M+1]
        kv = v.T[kw]  # NOTE: need to transpose eigenvectors
        print("eigenvalues 0-M+5:")
        print(w[np.flip(np.argsort(w))[0:M+5]])

        # cluster first M+1 eigenvectors
        km = cluster.k_means(kv.transpose(), n_clusters=M+1)
        km_lab = km[1]
        return(km_lab)

    def permute_covM(self, covM, clusters):
        """reorder covariance matrix to correspond to clustering output

        """

        counts = np.bincount(clusters)

        # identify noise cluster
        # NOTE: doesn't work when this assigns district to unique cluster
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
            V.append(v)
        nc = np.argmin(V)
        print(V)

        # reassign noise cluster to last index
        print(clusters)
        clustersP = np.copy(clusters)
        M = np.max(clusters)
        print(M)
        print(nc)
        for i in range(len(clustersP)):
            # flip noise cluster and last cluster
            if clustersP[i] == nc:
                clustersP[i] = M
            else:
                if clustersP[i] == M:
                    clustersP[i] = nc
        print(clustersP)

        covMC = np.copy(covM)
        indices = np.repeat(0, len(clustersP))
        tick = 0
        for i in range(len(counts)):
            for j in range(len(indices)):
                if clustersP[j] == i:
                    indices[j] = tick
                    tick += 1
        print(indices)

        return(covMC[np.ix_(indices, indices)])
