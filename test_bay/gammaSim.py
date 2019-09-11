import numpy as np
import math
import mosek
from mosek.fusion import *
from sklearn import cluster

class gammaSim:

    def __init__(self, N, J, eta, beta, lbdaJ, lbdaN, overlap=False, pg=1):
        """Short summary.

        Parameters
        ----------
        N : type
            Description of parameter `N`.
        J : type
            Description of parameter `J`.
        eta : type
            Description of parameter `eta`.
        beta : type
            Description of parameter `beta`.
            lower values produce more "signal"
        lbdaJ : type
            Description of parameter `lbdaJ`.
        lbdaN : type
            Description of parameter `lbdaN`.
        overlap : type
            Description of parameter `overlap`.
        pg : scalar
            Probability that at least one group is active in a given territory.

        """

        self.N = N  # number of districts
        self.J = J  # number of groups

        self.eta = eta  # probability of random killing
        self.beta = beta  # second parameter of beta dist, governs group attack probabilities
        self.lbdaJ = lbdaJ  # lambda, poisson parameter governing avg number of group members in territory
        self.lbdaN = lbdaN  # lambda, poisson parameter governing avg number of randos in each territory

        self.Jpop = np.zeros((self.J, self.N), dtype="int")  # group populations J rows, N columns
        self.Rpop = np.random.poisson(self.lbdaN, size=self.N)  # rando populations

        if overlap == False:
            self.Jid = np.zeros(N, dtype="int")  # group ids for each district
            for i in range(N):
                # select whether or not there is a group present
                g = np.random.uniform(0,1)
                if g <= pg:
                    # select group at random
                    u = np.random.uniform(0,1)
                    g = math.floor(u*J)
                    for j in range(J):  # fill in group populations
                        if j == g:
                            self.Jpop[j, i] = np.random.poisson(self.lbdaJ)
                            self.Jid[i] = j
                        else:
                            self.Jpop[j, i] = 0
                else:
                    self.Jid[i] = -1 # no group present
        else:
            pass

    def simT(self, T):

        self.A = np.zeros((self.N, T))  # attack matrix, N rows T columns

        for t in range(T):
            eJ = np.random.beta(2, self.beta, size=self.J) # draw attack probabilities
            for n in range(self.N):
                aR = np.random.binomial(self.Rpop[n], self.eta)  # number of random attacks
                self.A[n, t] += aR
                for j in range(self.J):
                    aJ = np.random.binomial(self.Jpop[j, n], eJ[j])  # number of organized attacks
                    self.A[n, t] += aJ

    def covMat(self):

        self.covA = np.cov(self.A)

    def traceMin(self):
        with Model("sdo1") as M:
            # target
            X = M.variable("X", Domain.inPSDCone(self.N))

            # coefficients
            C = Matrix.diag(self.N, 1)
            Aset = []
            bl = []
            bu = []
            for i in range(self.N):
                for j in range(i, self.N):
                    a = Matrix.sparse(self.N, self.N, [i], [j], 1)
                    Aset.append(a)  # a bunch of sparse matrices with ones to constrain each individual observation
                    if (i != j):
                        # multiplying by two recovers alphas in TW framework
                        # mosek unhappy with this on my laptop though
                        bl.append(self.covA[i, j])
                        bu.append(self.covA[i, j])
                    else:
                        bl.append(0)  # lower constraints are entries of covA except for diagonal
                        bu.append(self.covA[i, j])

            # setup objective
            M.objective(ObjectiveSense.Minimize, Expr.dot(C, X))

            # Constraints
            for i in range(len(Aset)):
                index = str(i)
                # print(Aset[i])
                M.constraint("cl"+index, Expr.dot(Aset[i], X), Domain.greaterThan(bl[i])) # lower
                M.constraint("cu"+index, Expr.dot(Aset[i], X), Domain.lessThan(bu[i])) # upper

            M.solve()

            self.gammaL = X.level().reshape(self.N, self.N)
            # return(X.level())

    def dbscan(self, eps, minP=5):

        print(minP)
        self.clstr_DBSCAN = cluster.DBSCAN(eps=eps, min_samples=minP).fit_predict(self.gammaL)

    def kmeans(self, k):

        self.clstr_kmeans = cluster.KMeans(n_clusters=k).fit_predict(self.gammaL)
