### SETUP ###

# rm(list = ls())
source("../01_code/00_params.R")

libs <- c("tidyverse", "reshape2", "patchwork", "ggnewscale", "scales")
ipak(libs)

Bhat <- read_csv(Bhat_mean_path) %>% as.matrix()
J <- gangs_V + 1

### CLEAN ###

rownames(Bhat) <- colnames(Bhat)

# swap peaceful to edge
gang_names <- setdiff(colnames(Bhat), "peaceful")
# Bhat_names_order <- c(gang_names, "peaceful")

# filter out peaceful cluster
Bhat <- Bhat[gang_names, gang_names]

turf_cols <- c(gd_col, bps_col, lk_col, vl_col, bd_col, ts_col)
col_mapping_turf <- data.frame(gang_names, turf_cols)
colnames(col_mapping_turf) <- c("gang", "color")


Bhat_melted <- melt(Bhat)
# nrow(Bhat_melted)
Bhat_melted$id_i <- rep(seq(1, J-1), J-1)
Bhat_melted$id_j <- rep(seq(1, J-1), rep(J-1, J-1))
Bhat_melted <- as_tibble(Bhat_melted)
colnames(Bhat_melted) <- c("gang_i", "gang_j", "b_ij", "id_i", "id_j") 
# Bhat_melted <- Bhat_melted %>% dplyr::select(-Var1, -Var2)

# col_mapping$cluster <- as.integer(col_mapping$cluster) - 1
Bhat_melted <- left_join(Bhat_melted, col_mapping_turf, by=c("gang_i"="gang"))
colnames(Bhat_melted)[colnames(Bhat_melted)=="color"] <- "color_i"
Bhat_melted <- left_join(Bhat_melted, col_mapping_turf, by=c("gang_j"="gang"))
colnames(Bhat_melted)[colnames(Bhat_melted)=="color"] <- "color_j"

# flop noise cluster
# Bhat_melted$g1 <- ifelse(Bhat_melted$g1==nc, K+1, Bhat_melted$g1)
# Bhat_melted$g1 <- ifelse(Bhat_melted$g1==K, nc, Bhat_melted$g1)
# Bhat_melted$g1 <- ifelse(Bhat_melted$g1==K+1, K, Bhat_melted$g1)

# Bhat_melted$g2 <- ifelse(Bhat_melted$g2==nc, K+1, Bhat_melted$g2)
# Bhat_melted$g2 <- ifelse(Bhat_melted$g2==K, nc, Bhat_melted$g2)
# Bhat_melted$g2 <- ifelse(Bhat_melted$g2==K+1, K, Bhat_melted$g2)

# col_mapping$cluster <- ifelse(col_mapping$cluster==nc, K+1, col_mapping$cluster)
# col_mapping$cluster <- ifelse(col_mapping$cluster==K, nc, col_mapping$cluster)
# col_mapping$cluster <- ifelse(col_mapping$cluster==K+1, K, col_mapping$cluster)
# col_mapping <- col_mapping %>% as_tibble() %>% arrange(desc(cluster))

# drop noise cluster
# Bhat_melted <- Bhat_melted %>% filter(g1!=nc & g2!=nc)

# Bhat_melted_diag <- Bhat_melted %>% filter(Bhat_melted$g1==Bhat_melted$g2)
# Bhat_melted_diag <- Bhat_melted_diag %>% arrange(desc(g1))
# Bhat_melted_diag$color1 <- Bhat_melted_diag$color1 %>% as.character()

# bhatColors <- colorRampPalette(c("white", "#696969"))(10)
hmColors <- colorRampPalette(c("white", bcOrange))(10)
# show_col(Bhat_melted_diag$color1)

# Bhat_melted$g1 <- ifelse(Bhat_melted$g1 > nc, Bhat_melted$g1-1, Bhat_melted$g1)
# Bhat_melted$g2 <- ifelse(Bhat_melted$g2 > nc, Bhat_melted$g2-1, Bhat_melted$g2)

# Bhat_melted_diag$g1 <- ifelse(Bhat_melted_diag$g1 > nc, Bhat_melted_diag$g1-1, Bhat_melted_diag$g1)
# Bhat_melted_diag$g2 <- ifelse(Bhat_melted_diag$g2 > nc, Bhat_melted_diag$g2-1, Bhat_melted_diag$g2)

# Bhat_melted_diag <- Bhat_melted_diag %>% arrange(g1)

### FIGURE ###

Bhat_hm <- ggplot(data=Bhat_melted, aes(x=id_i, y=id_j, fill=b_ij)) + 
  geom_tile(colour="white", width=.9, height=.9) +
  scale_fill_gradient(low=hmColors[1], high=hmColors[length(hmColors)]) +
  theme_classic() +
  coord_fixed() +
  scale_y_continuous(trans = "reverse", breaks=seq(1, J-1), labels=gang_names) +
  scale_x_continuous(breaks=seq(1, J-1), labels=gang_names) +
  theme(legend.position = "none",
        axis.line=element_blank(),
        # axis.title.x=element_blank(),
        axis.text.x=element_text(angle=45, hjust = 1),
        axis.ticks.x=element_blank(),
        axis.title.y=element_blank(),
        axis.text.y=element_text(),
        axis.ticks.y=element_blank()) +
  labs(x=" ", y=" ", title="Inter- and Intra-Gang Conflict Intensities")
# Bhat_hm
