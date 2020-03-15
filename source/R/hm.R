hm <- function(meltedDF, plot_title="") {
  out <- ggplot(data=meltedDF, aes(x=Var2, y=Var1, fill=value)) + 
    geom_tile() +
    scale_fill_gradient(low=hmColors[1], high=hmColors[length(hmColors)]) +
    theme_classic() +
    coord_fixed()  +
    scale_y_continuous(trans = "reverse") +
    labs(title=plot_title) +
    theme(legend.position = "none",
          axis.line=element_blank(),
          axis.title.x=element_blank(),
          axis.text.x=element_blank(),
          axis.ticks.x=element_blank(),
          axis.title.y=element_blank(),
          axis.text.y=element_blank(),
          axis.ticks.y=element_blank())
  return(out)
}