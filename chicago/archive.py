
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
