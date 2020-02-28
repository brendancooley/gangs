### SETUP ###

rm(list = ls())
source("../01_code/00_params.R")

libs <- c("tidyverse", "reshape2", "patchwork")
ipak(libs)

P <- read_csv(P_path, col_names=FALSE) %>% as.matrix()
P_sorted <- read_csv(P_sorted_path, col_names=FALSE) %>% as.matrix()
clusters <- read_csv(clusters_path, col_names=FALSE) %>% pull(.)
geoids_keep <- read_csv(geoids_keep_path, col_names=FALSE) %>% pull(.)
geoids_zero <- read_csv(geoids_zero_path, col_names=FALSE) %>% pull(.)
nc <- read_csv(nc_path, col_names=FALSE) %>% pull(.) # noise cluster

### CLEAN ###

clusters_keep_df <- data.frame(clusters, geoids_keep)
colnames(clusters_keep_df) <- c("cluster", "GEOID")
zero_df <- data.frame(nc, geoids_zero)
colnames(zero_df) <- c("cluster", "GEOID")

clusters_df <- bind_rows(clusters_keep_df, zero_df) %>% as_tibble()
clusters_df$cluster <- as.factor(clusters_df$cluster)

colnames(P) <- seq(1, nrow(P))
colnames(P_sorted) <- seq(1, nrow(P_sorted))

P_melted <- melt(P)
P_melted$value <- ifelse(P_melted$value < 0, 0, P_melted$value)
P_sorted_melted <- melt(P_sorted)
P_sorted_melted$value <- ifelse(P_sorted_melted$value < 0, 0, P_sorted_melted$value)

# summary(P_melted)
hmColors <- colorRampPalette(c("white", bcOrange))(10)

### FIGURES ###

P_hm <- ggplot(data=P_melted, aes(x=Var1, y=Var2, fill=value)) + 
  geom_tile() +
  scale_fill_gradient(low=hmColors[1], high=hmColors[length(hmColors)]) +
  theme_classic() +
  coord_fixed()  +
  scale_y_continuous(trans = "reverse") +
  theme(legend.position = "none",
        axis.line=element_blank(),
        axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        axis.title.y=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank()) +
  labs(x=" ", y=" ", title="Covariance Matrix (Unsorted)", subtitle="(Diagonal Entries, Negative Entries = 0)") +
  annotate("rect", xmin=0, ymin=0, xmax=nrow(P), ymax=nrow(P), alpha=0, size=.5, color="black")

cluster_counts <- table(clusters_df$cluster)
end <- cluster_counts[length(cluster_counts)]
cluster_counts[rownames(cluster_counts) == as.character(nc)] <- end  # replace noise cluster with last cluster

# calculate effective noise cluster size (w/o zero vectors)
nc_size <- nrow(P) - sum(cluster_counts[-length(cluster_counts)])
cluster_counts[length(cluster_counts)] <- nc_size

P_hm_sorted <- ggplot(data = P_sorted_melted, aes(x=Var1, y=Var2, fill=value)) + 
  geom_tile() +
  scale_fill_gradient(low=hmColors[1], high=hmColors[length(hmColors)]) +
  theme_classic() +
  coord_fixed() +
  scale_y_continuous(trans = "reverse") +
  theme(legend.position = "none",
        axis.line=element_blank(),
        axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        axis.title.y=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank()) +
  labs(x=" ", y=" ", title="Covariance Matrix (Sorted)", subtitle="(Diagonal Entries, Negative Entries = 0)") +
  annotate("rect", xmin=0, ymin=0, xmax=nrow(P), ymax=nrow(P), alpha=0, size=.5, color="black")

coord <- 0
for (j in cluster_counts) {
  P_hm_sorted <- P_hm_sorted +
    annotate("rect", xmin=coord, ymin=coord, xmax=coord+j, ymax=coord+j, alpha=0, size=.5, color="black")
  coord <- coord + j
}

block_hm <- P_hm + P_hm_sorted
