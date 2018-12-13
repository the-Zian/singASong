#Purpose: Generate visuals


library(data.table)
suppressMessages(library(tidyverse))
library(reshape2)
library(stringr)
library(wesanderson)
library(RColorBrewer)


# Read in cleaned data
songs <- read_csv('data/songs_cleaned.csv')


###################
# PLOTS
theme_set(theme_minimal())

genres_list <- c("blues", "brassmilitary", "childrens", "electronic", "folkworldcountry", "funksoul", "hiphop", "jazz", 
                  "latin", "non", "non-music", "pop", "reggae", "rock", "stage_screen")
genre_labels <- c('Blues', 'Brass/Military', 'Children\'s', 'Electronic', 'Folk/World/Country', 'Funk/Soul', 'Hip-Hop', 
                  'Jazz', 'Latin', 'None', 'Non-music', 'Pop', 'Reggae', 'Rock', 'Stage/Screen')
names(genre_labels) <- genres_list

tol18rainbow = list("#771155", "#AA4488", "#CC99BB", "#114477", "#4477AA", "#77AADD", "#117777", "#44AAAA", "#77CCCC", 
                    "#777711", "#AAAA44", "#DDDD77", "#774411", "#AA7744", "#DDAA77", "#771122", "#AA4455", "#DD7788")
names(tol18rainbow) <- genre_labels

# Stacked bar plot of genres by decade
songs <- songs %>% mutate(decade=floor(year/10)*10)
# Calculate number of genres per decade
genre_vars <- names(songs)[grep('^genre\\.', names(songs))]
genres <- songs %>% select(decade, !!genre_vars) %>%
    group_by(decade) %>%
    summarise_at(.vars=genre_vars, .funs=sum) %>%
    melt(id.vars='decade', measure.vars=genre_vars, variable.name='genre') %>%
    group_by(decade) %>%
    mutate(n=sum(value), value=value/n) %>%
    mutate(genre=str_replace(genre, 'genre\\.', '')) 


p <- ggplot(genres, aes(decade, value, fill=genre)) +
    geom_col(alpha=0.8) +
    scale_x_continuous(labels=seq(1930,2020,10), breaks=seq(1930,2020,10)) +
    scale_fill_manual(name='Genre', values=tol18rainbow, labels=genre_labels) +
    labs(x='', y='', title='Genre Proportions', subtitle='Genres are not mutually exclusive')
ggsave('report/genre_decade.png', p, device='png', dpi=320)

# Model evaluation: AUCs by K, genre
genres9 <- c(1,4:7,9,12:14)
auc_matrix <- matrix(NA, 5, length(genres9))

for(i in 1:5) {
  auc_matrix[i,] <- roc_tbls[[i]] %>% sapply(function(x) x$auc)
}

colnames(auc_matrix) <- genre_labels[genres9]

genre_AUCs <- data.frame(K = 10*(1:5)) %>%
  cbind(as.data.frame(auc_matrix)) %>%
  melt(id.vars = "K", variable.name = "Genre", value.name = "AUC") 

genre_AUC_plot <- genre_AUCs %>%
  ggplot(aes(x = K, y = AUC, col = Genre)) +
  geom_line() +
  geom_point(pch = 18, size = 2) +
  scale_colour_manual(name = "Genre", values = tol18rainbow[genres9] %>% unlist(), labels = names(tol18rainbow)[genres9]) +
  labs(title = "Genre classifier performance on test data",
       subtitle = "Logistic regression with LDA-derived features",
       x = "K (number of topics)",
       y = "Test AUC")

ggsave('report/model_aucs.png', plot = genre_AUC_plot, device = 'png', dpi = 320)

# Model evaluation: ROC
roc_tbls_only <- lapply(roc_tbls[[3]], function(x) x$roc_tbl)

for(i in 1:length(roc_tbls_only)) {
  roc_tbls_only[[i]] <- roc_tbls_only[[i]] %>%
    mutate(Genre = names(tol18rainbow)[genres9[i]])
}

roc_tbl_k30 <- bind_rows(roc_tbls_only)

genre_ROC_plots <- roc_tbl_k30 %>%
  ggplot(aes(x = 1 - Specificity, y = Sensitivity, col = Genre)) +
  geom_line(size = 1) +
  geom_abline(intercept = 0, slope = 1, size = 1) +
  scale_colour_manual(name = "Genre", values = tol18rainbow[genres9] %>% unlist(), labels = names(tol18rainbow)[genres9]) +
  labs(title = "ROC curves by genre",
       subtitle = "K = 30 topics",
       x = "False positive rate",
       y = "True positive rate") +
  lims(x = c(0,1), y = c(0,1))

ggsave('report/roc_curves_k30.png', plot = genre_ROC_plots, device = 'png', dpi = 320)

# Model evaluation: calibration plots
genre_labels <- c('Blues', 'Brass/Military', 'Childrens', 'Electronic', 'Folk/World/Country', 'Funk/Soul', 'Hip-Hop', 
                  'Jazz', 'Latin', 'None', 'Non-music', 'Pop', 'Reggae', 'Rock', 'Stage/Screen')
genre9_labels <- c('Blues', 'Electronic', 'Folk/World/Country', 'Funk/Soul', 'Hip-Hop', 
                  'Latin', 'Pop', 'Reggae', 'Rock')
genres9_list <- c("blues", "electronic", "folkworldcountry", "funksoul", "hiphop", "latin", "pop", "reggae", "rock")
names(genre9_labels) <- genres9_list

makeCalibration<- function(df, genre) {
  prob_var <- paste0("prob.", genre)
  genre_var <- paste0("genre.", genre)
  df$prob_round <- unlist(round(df[, prob_var], 1))
  df$genre_var <- df[, genre_var]
  df <- df %>%
    group_by(prob_round) %>%
    summarise(prob_emp = sum(genre_var)/n(), n = n()) %>%
    na.omit() %>%
    mutate(Genre = genre)
  return(df)
}

calibration_list <- vector("list", length(genres9_list))
for(i in 1:length(calibration_list)) {
  calibration_list[[i]] <- makeCalibration(test_list[[3]], genres9_list[i])
}
calibration_tbl <- bind_rows(calibration_list)


calibration_plot <- ggplot(calibration_tbl, aes(x = prob_round, y = prob_emp, size = n)) +
  geom_abline(intercept = 0, slope = 1) +
  geom_point(aes(col = Genre), alpha = 0.9, show.legend = FALSE) +
  scale_colour_manual(name = "Genre", values = as.character(tol18rainbow[genres9] %>% unlist()), labels = genre_labels[genres9], guide = FALSE) +
  facet_wrap(~Genre, labeller = labeller(Genre = genre9_labels)) +
  labs(title = "Model calibration by genre",
       subtitle = "K = 30 topics",
       x = "Predicted probability (rounded to nearest 10%)",
       y = "Empirical probability")

ggsave('report/calibration_k30.png', plot = calibration_plot, device = 'png', dpi = 320)
