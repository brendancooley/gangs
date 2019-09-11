library(extraDistr)
library(Matrix)

### HELPERS ###

# violence potential function
vpf <- function() {
  
}
# note: version in writeup depends only on overall group strength
# do we want to have a notion of territorial strongholds?
# how does this relate to violence during periods of war?

### SIMULATION ###

P <- 10  # macro periods
p <- 10  # micro periods

N <- 20 # number of districts
popR <- rpois(20, 10) # population of randos in each district
J <- 3 # number of groups
popJ <- list()

pWar <- .2  # probability a war breaks out between any two groups in any macro period

# initialize group vectors
for (j in 1:J) {
  popJ[[j]] <- rep(0, N)
}

# enforce that at least one group in every district and non-overlapping
cluster <- rep(0, N)
for (i in 1:N) {
  # randomly select a group
  u <- runif(1)
  g <- ceiling(u * J)
  for (j in 1:J) {
    if (j==g) {
      popJ[[j]][i] <- rtpois(1, 5, a=1)  # at least one member
      cluster[i] <- j
    } else {
      popJ[[j]][i] <- 0
    }
  }
}

# War matrices
W <- list()
for (p in 1:P) {
  w <- Matrix(0, ncol=J, nrow=J)
  for (i in 2:J) {
    top <- i - 1
    for (j in 1:top) {
      w[i, j] <- w[j, i] <- rbern(1, pWar)
    }
  }
  W[[p]] <- w
}

