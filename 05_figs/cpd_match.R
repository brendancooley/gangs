source("../01_code/00_params.R")

libs <- c("knitr", "kableExtra", "stringi", "patchwork")
ipak(libs)

label_counts <- read_csv(label_counts_path) %>% filter(owner != "peaceful") %>% arrange(desc(count))
label_counts$count <- label_counts$count / L
colnames(label_counts) <- c("Gang", "Proportion")
label_counts$Gang <- stri_trans_totitle(label_counts$Gang)

label_counts_table <- kable(label_counts, "latex", booktabs=T, caption="Matched-Gang Counts \\label{tab:label_counts}") %>%
  kable_styling(latex_options = c("striped"))

save_kable(label_counts_table, "chicago/matched_gang_counts.png")
