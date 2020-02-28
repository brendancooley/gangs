### SETUP ###

rm(list = ls())
source("../01_code/00_params.R")

libs <- c("tidyverse")
ipak(libs)

J <- read_csv(J_path, col_names=FALSE) %>% pull(.)
K <- J - 1
eigs <- read_csv(eig_path, col_names=FALSE)

### CLEAN ###

colnames(eigs) <- c("lbda")
eigs <- eigs %>% arrange(desc(lbda))
eigs$id <- seq(1, nrow(eigs))

### FIGURE ###

cut <- eigs %>% filter(id==J) %>% pull(lbda)
screePlot <- ggplot(eigs %>% filter(id <= screeN), aes(x=id, y=lbda)) +
  geom_point() +
  geom_hline(yintercept=cut, lty=2) +
  theme_classic() + 
  labs(title="Leading Eigenvalues of Covariance Matrix", subtitle="(Off-Diagonal Entries)", y="Eigenvalue") +
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank()) +
  theme(aspect.ratio=1)
