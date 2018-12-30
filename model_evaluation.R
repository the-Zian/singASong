library(reshape2)
library(tidyverse)

theme_set(theme_minimal())

auc_matrix <- matrix(NA, 5, length(genres))

for(i in 1:5) {
  auc_matrix[i,] <- roc_tbls[[i]] %>% sapply(function(x) x$auc)
}

colnames(auc_matrix) <- genres

genre_AUCs <- data.frame(K = 10*(1:5)) %>%
  cbind(as.data.frame(auc_matrix)) %>%
  melt(id.vars = "K", variable.name = "Genre", value.name = "AUC") 

genre_AUC_plot <- genre_AUCs %>%
  ggplot(aes(x = K, y = AUC, col = Genre)) +
  geom_line(size = 0.5) +
  labs(title = "Genre classifier performance on test data",
       subtitle = "") 

genre_AUC_plot
