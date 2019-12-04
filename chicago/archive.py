
### TRACE MINIMIZATION ###
if not os.path.exists(gammaL_path):
    start_time = time.time()
    gammaL = helpers.traceMin(covM)
    print("trace minimization completed in %s seconds" % (time.time() - start_time))
    # (N=200): trace minimization completed in 2218.314126968384 seconds
    np.savetxt(gammaL_path, gammaL, delimiter=",")

# diagnostics
gammaL = np.genfromtxt(gammaL_path, delimiter=",")
gammaL_cor = np.corrcoef(gammaL)
np.trace(covM)
np.trace(gammaL)


loss_k = []
ord = np.arange(k)
perms = []
for perm in permutations(ord):
    perms.append(np.array(perm))

for p in perms:
    print(p)
    theta = np.eye(k)[clusters][:,p]
    # np.sum(theta, axis=0)
    delta = np.diag(np.sum(theta, axis=0))
    print(delta)
    theta_tilde = theta[0:rowN,]
    delta_tilde = np.diag(np.sum(theta_tilde, axis=0))
    Bhat = np.linalg.inv(delta_tilde) @ theta_tilde.transpose() @ Ptilde @ theta @ np.linalg.inv(delta)

    P_hat = theta @ Bhat @ theta.transpose()
    P_hat = P_hat - np.diag(np.diag(P_hat))
    Pv_hat = P_hat[rowN:,]

    loss = np.linalg.norm(Pv - Pv_hat, ord="fro")  # Frobenius Norm
    loss_k.append(loss)
