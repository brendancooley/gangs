import numpy as np
import mosek
from mosek.fusion import *

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
            A[:,0] += .001  # add small value to first period to eliminate zeros
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
            min_eig = np.min(np.real(np.linalg.eigvals(covA)))
            if min_eig < 0:
                covA -= 10*min_eig * np.eye(*covA.shape)
            print(str(z) + " of " + str(covA.shape[0] ** 2) + " negative entries found and converted to zeros")
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
