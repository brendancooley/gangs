### SETUP ###

rm(list = ls())
source("../01_code/00_params.R")

libs <- c("tidyverse", "rgdal", "sf", "tmap", "tigris", "lubridate")
ipak(libs)

crimes_clean <- read_csv(crimes_clean_path)
pop <- read_csv(pop_path)

th_mat <- read_csv(th_mat_path, col_names=F)
ts_mat <- read_csv(ts_mat_path, col_names=F)
tn_mat <- read_csv(tn_mat_path, col_names=F)

### CLEAN ###

homicides_t <- colSums(th_mat)
hnfs_t <- colSums(ts_mat)
narcotics_t <- colSums(tn_mat)
period_t <- seq(min(crimes_clean[[aggregation]]), max(crimes_clean[[aggregation]]), by=aggregation)

counts_t <- data.frame(homicides_t, hnfs_t, narcotics_t, period_t) %>% as_tibble()
counts_t$year <- year(counts_t$period_t)
counts_t <- left_join(counts_t, pop)
counts_t$`homicide rate` <- counts_t$homicides_t / counts_t$population * 100000
counts_t$`shooting rate` <- counts_t$hnfs_t / counts_t$population * 100000
counts_t$narcotics_100000 <- counts_t$narcotics_t / counts_t$population * 100000

counts_t_cat <- counts_t %>% gather(key="type", value="rate", `homicide rate`, `shooting rate`, narcotics_100000) %>% filter(type!="narcotics_100000")

### FIGURE ###

hnfs_t_plot <- ggplot(counts_t_cat, aes(x=period_t, y=rate, color=type)) +
  geom_line(alpha=.5) +
  # geom_smooth(method="loess", color="red", se=FALSE) +
  theme_classic() +
  labs(x="Month", y="Homicides and Non-Fatal Shootings per 100,000", title="Homicides and Non-Fatal Shootings") +
  scale_color_grey() +
  theme(aspect.ratio=1)
# ggsave(filename="figs/hnfs_t_plot.png", plot=hnfs_t_plot, width=6, height=6)

narcotics_t_plot <- ggplot(counts_t, aes(x=period_t, y=narcotics_100000)) +
  geom_line(alpha=.5) +
  geom_smooth(method="loess", color="red", se=FALSE, size=.5) +
  theme_classic() +
  labs(x="Month", y="Narcotics Arrests per 100,000", title="Narcotics Arrests") +
  theme(aspect.ratio=1)
# ggsave(filename="figs/narcotics_t_plot.png", plot=narcotics_t_plot, width=6, height=6)