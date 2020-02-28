### SETUP ###

rm(list = ls())
source("../01_code/00_params.R")

libs <- c("tidyverse", "reshape2", "patchwork", "ggnewscale")
ipak(libs)

Bhat <- read_csv(Bhat_path, col_names=FALSE) %>% as.matrix()
J <- read_csv(J_path, col_names=FALSE) %>% pull(.)
K <- J - 1
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

# match representative districts
lk_id <- clusters_df %>% filter(GEOID==lk_geoid) %>% pull(cluster) %>% as.integer() - 1
gd_id <- clusters_df %>% filter(GEOID==gd_geoid) %>% pull(cluster) %>% as.integer() - 1
vl_id <- clusters_df %>% filter(GEOID==vl_geoid) %>% pull(cluster) %>% as.integer() - 1

known_ids <- c(lk_id, gd_id, vl_id, nc)
known_cols <- c(lk_col, gd_col, vl_col, nc_col)

# construct color mapping
col_mapping <- data.frame(known_ids, known_cols)
colnames(col_mapping) <- c("cluster", "color")

other_ids <- setdiff(clusters_df$cluster %>% unique(), known_ids) %>% as.integer()
other_cols <- rep(other_col, length(other_ids))
col_mapping_other <- data.frame(other_ids, other_cols)
colnames(col_mapping_other) <- c("cluster", "color")

col_mapping <- bind_rows(col_mapping, col_mapping_other)
col_mapping$cluster <- as.factor(col_mapping$cluster)

Bhat_melted <- melt(Bhat)
nrow(Bhat_melted)
Bhat_melted$g1 <- rep(seq(0, J-1), J)
Bhat_melted$g2 <- rep(seq(0, J-1), rep(J, J))
Bhat_melted <- as_tibble(Bhat_melted)
Bhat_melted <- Bhat_melted %>% select(-Var1, -Var2)

col_mapping$cluster <- as.integer(col_mapping$cluster) - 1
Bhat_melted <- left_join(Bhat_melted, col_mapping, by=c("g1"="cluster"))
colnames(Bhat_melted)[colnames(Bhat_melted)=="color"] <- "color1"
Bhat_melted <- left_join(Bhat_melted, col_mapping, by=c("g2"="cluster"))
colnames(Bhat_melted)[colnames(Bhat_melted)=="color"] <- "color2"

# flop noise cluster
Bhat_melted$g1 <- ifelse(Bhat_melted$g1==nc, K+1, Bhat_melted$g1)
Bhat_melted$g1 <- ifelse(Bhat_melted$g1==K, nc, Bhat_melted$g1)
Bhat_melted$g1 <- ifelse(Bhat_melted$g1==K+1, K, Bhat_melted$g1)

Bhat_melted$g2 <- ifelse(Bhat_melted$g2==nc, K+1, Bhat_melted$g2)
Bhat_melted$g2 <- ifelse(Bhat_melted$g2==K, nc, Bhat_melted$g2)
Bhat_melted$g2 <- ifelse(Bhat_melted$g2==K+1, K, Bhat_melted$g2)

col_mapping$cluster <- ifelse(col_mapping$cluster==nc, K+1, col_mapping$cluster)
col_mapping$cluster <- ifelse(col_mapping$cluster==K, nc, col_mapping$cluster)
col_mapping$cluster <- ifelse(col_mapping$cluster==K+1, K, col_mapping$cluster)
col_mapping <- col_mapping %>% as_tibble() %>% arrange(desc(cluster))

# drop noise cluster
Bhat_melted <- Bhat_melted %>% filter(g1!=K & g2!=K)

Bhat_melted_diag <- Bhat_melted %>% filter(Bhat_melted$g1==Bhat_melted$g2)
Bhat_melted_diag <- Bhat_melted_diag %>% arrange(desc(g1))

bhatColors <- colorRampPalette(c("white", "#696969"))(10)
hmColors <- colorRampPalette(c("white", bcOrange))(10)

### FIGURE ###

Bhat_hm <- ggplot(data = Bhat_melted, aes(x=g1, y=g2, fill=value)) + 
  geom_tile(colour="white", width=.9, height=.9) +
  scale_fill_gradient(low=hmColors[1], high=bhatColors[length(bhatColors)]) +
  new_scale_fill() +
  geom_tile(data=Bhat_melted_diag, aes(fill=forcats::fct_inorder(Bhat_melted_diag$color1)), colour="white", width=.9, height=.9) +
  scale_fill_manual(values=Bhat_melted_diag$color1) +
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
  labs(x=" ", y=" ", title="Inter-Gang Conflict Intensities")

