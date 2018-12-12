library(tidytext)
library(tidyverse)
library(tm)
library(topicmodels)

ks <- (1:5)*10
lda_list <- gamma_list <- vector("list", 5)

for(i in 1:length(ks)) {
  lda_list[[i]] <- readRDS(paste0("lda_song_ngram1_k", ks[i], ".rds"))
  gamma_list[[i]] <- lda_list[[i]]@gamma %>%
    as.data.frame %>%
    as.tbl()
}

train <- train %>%
  as.data.frame()
train <- train[,c(1:27,416:417)] %>% as.tbl()

train <- train %>%
  as.data.frame()
test <- test[,c(1:27,416:417)] %>% as.tbl()

## Obtain gammas
gamma_train <- lapply(gamma_list, function(gamma) gamma[train.idx,])
gamma_test <- lapply(gamma_list, function(gamma) gamma[test.idx,])

## Merge gammas 
train_list <- lapply(gamma_train, function(df) bind_cols(train, df) %>% as.tbl())
test_list <- lapply(gamma_test, function(df) bind_cols(test, df) %>% as.tbl())

## Run logistic regression models
genres <- c("blues", "classical", "electronic", "folkworldcountry", "funksoul", "hiphop", "jazz", "latin", "pop", "reggae", "stagescreen")
model_list <- vector("list", 5)
for(i in 1:5) {
  model_list[[i]] <- vector("list", length(genres))
}
for(i in 1:5) {
  formula_tail <- paste0("~", (paste0("V", 1:(i*10)) %>% glue::glue_collapse(sep = "+")))
  for(j in 1:length(genres)) {
    genre <- paste0("genre.", genres[j])
    model_formula <- formula(paste0(genre, formula_tail))
    model_list[[i]][[j]] <- glm(model_formula, data = train_list[[i]], family = binomial)
  }
}

extract_fit <- function(model) {
  summary(model)$deviance/summary(model)$null.deviance
}

fit_list <- vector("list", 5)
for(i in 1:5) {
  fit_list[[i]] <- lapply(model_list[[i]], extract_fit)
}

gamma_list[[1]]

plot_beta_spread(lda_list[[1]], n = 10)
