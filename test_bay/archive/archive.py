    def W(self, A):

        W = np.zeros((A.shape[0], A.shape[0]))
        for i in range(len(A)):
            for j in range(len(A)):
                W[i, j] = self.affinity(A[i, ], A[j, ])

        return(W)

    def affinity(self, x1, x2, sigma=1):
        xnorm = np.linalg.norm(x1 - x2)
        out = np.exp(-1 * xnorm ** 2 / (2 * sigma ** 2))
        return(out)
