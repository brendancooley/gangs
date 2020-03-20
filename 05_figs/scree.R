### SETUP ###

# rm(list = ls())
source("../01_code/00_params.R")

libs <- c("tidyverse", "matrixStats")
ipak(libs)

J <- read_csv(J_path, col_names=FALSE) %>% pull(.)
K <- J - 1
eigs <- read_csv(eig_path, col_names=FALSE)

J_all <- read_csv(J_all_path, col_names=FALSE) %>% pull(.)
K_all <- J_all - 1
K_all <- K_all %>% sort()

K_lower <- K_all[3]
K_upper <- K_all[97]

K_mid <- (K_upper - K_lower) / 2

eigs_mat <- matrix(nrow=L, ncol=50)
for (i in 1:L) {
  eigs_i <- read_csv(paste0(eig_bs_path, i, ".csv"), col_names=FALSE) %>% arrange(desc(X1)) %>% pull()
  eigs_mat[i, ] <- eigs_i[1:50]
}

eig_ci <- colQuantiles(eigs_mat, probs=c(.025, .5, .975)) %>% as_tibble()
colnames(eig_ci) <- c("lb", "mid", "ub")
eig_ci$id <- seq(1, nrow(eig_ci))

cut_lower <- eig_ci %>% filter(id==K_lower+1) %>% pull(mid)
cut_upper <- eig_ci %>% filter(id==K_upper+1) %>% pull(mid)

cut <- (cut_lower - cut_upper) / 2 + cut_upper

### CLEAN ###

colnames(eigs) <- c("lbda")
eigs <- eigs %>% arrange(desc(lbda))
eigs$id <- seq(1, nrow(eigs))
# cut <- eigs %>% filter(id==J) %>% pull(lbda)

### FIGURE ###

screePlot <- ggplot(data=eig_ci) +
  geom_point(aes(x=id, y=mid), size=.5) +
  geom_segment(aes(x=id, xend=id, y=lb, yend=ub)) +
  geom_hline(yintercept=cut, lty=2) +
  theme_classic() + 
  labs(title="Leading Eigenvalues of Covariance Matrix", subtitle="(Off-Diagonal Entries)", y="Eigenvalue") +
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank()) +
  theme(aspect.ratio=1)
