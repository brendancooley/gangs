source("../01_code/00_params.R")

libs <- c("tidyverse")
ipak(libs)

area_min <- 2000000
gang_area_means <- read_csv(paste0(gang_territory_path, "gang_area_means.csv"))

gang_area_plot_data <- gang_area_means %>% filter(area_mean>area_min)
gang_area_other <- gang_area_means %>% filter(area_mean<area_min) %>% pull(area_mean) %>% sum()
gang_area_plot_data <- gang_area_plot_data %>% add_row(gang="", area_mean=0)
gang_area_plot_data <- gang_area_plot_data %>% add_row(gang="other", area_mean=gang_area_other)

gang_area_plot <- gang_area_plot_data %>% ggplot(aes(x=factor(gang, gang_area_plot_data$gang), y=area_mean)) +
  geom_bar(stat="identity", fill=bcOrange) +
  theme_classic() +
  theme(axis.text.x=element_text(angle = 60, hjust=1,vjust=1),
        axis.ticks.x=element_blank(),
        axis.title.x=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank()) +
  labs(y=paste0("Average territorial extent"), title=paste0("Chicago Gang Turf, ", bruhn_sy, "-", bruhn_ey))
