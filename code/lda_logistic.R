ks <- (1:5)*10
lda_list <- gamma_list <- vector("list", 5)

for(i in 1:length(ks)) {
  lda_list[[i]] <- readRDS(paste0("lda_song_ngram1_k", ks[i], ".rds"))
  gamma_list[[i]] <- lda_list[[i]]@gamma %>%
    as.data.frame %>%
    as.tbl()
  gamma_list[[i]] <- cbind(lda_list[[i]]@documents %>% as.numeric(), gamma_list[[i]])
}

gamma_list <- lapply(gamma_list, function(df) {names(df)[1] <- "song_id"; return(df)})
data_list <- lapply(gamma_list, function(df) {df <- merge(clean, df, by = "song_id", all.x = TRUE) %>% as.tbl(); return(df)})

set.seed(666)
train.idx <- sample(1:nrow(clean), size=0.7*nrow(clean))
test.idx <- which(!seq(nrow(clean)) %in% train.idx)

train_list <- lapply(data_list, function(df) df[train.idx,])
test_list <- lapply(data_list, function(df) df[test.idx,])

## Run logistic regression models
genres <- c("blues", "electronic", "folkworldcountry", "funksoul", "hiphop", "latin", "pop", "reggae", "rock")
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

## Make predictions on test set
pred_names <- paste0("prob.", genres)

for(i in 1:5) {
  for(j in 1:length(genres)) {
    test_list[[i]][, pred_names[j]] <- predict(model_list[[i]][[j]], newdata = test_list[[i]], type = "response")
  }
}

## Model performance - AUC
library(pROC)

roc_list <- vector("list", 5)
for(i in 1:5) {
  roc_list[[i]] <- vector("list", length(genres))
  for(j in 1:length(genres)) {
    roc_list[[i]][[j]] <- roc(response = test_list[[i]][, paste0("genre.", genres[j])] %>% pull(1), predictor = test_list[[i]][, pred_names[j]] %>% pull(1))
  }
}

## Functions for ROC plotting
## Extract sensitivity and specificity from ROC objects
makeROCtbl <- function(roc_obj) {
  roc_tbl <- tibble(Sensitivity = roc_obj$sensitivities,
                    Specificity = roc_obj$specificities)
  roc_auc <- auc(roc_obj)
  return_obj <- list(roc_tbl = roc_tbl, auc = roc_auc)
  
  return(return_obj)
}

## Create ROC curve
ggplotROC <- function(roc_tbl_list, k_ind, genre_ind) {
  genre <- genres[genre_ind]
  k <- 10*k_ind
  ggplot(roc_tbl_list[[k_ind]][[genre_ind]]$roc_tbl, aes(x = 1 - Specificity, y = Sensitivity)) +
    geom_line() +
    labs(title = paste0(genre, ", ", "K = ", k),
         subtitle = paste0("AUC: ", roc_tbl_list[[k_ind]][[genre_ind]]$auc %>% round(3)))
}

roc_tbls <- vector("list", 5)
for(i in 1:5) {
  roc_tbls[[i]] <- lapply(roc_list[[i]], makeROCtbl)
}

library(gridExtra)

## Homogeneity of topics
library(reshape2)

melted_k20 <- data_list[[2]] %>%
  filter(artist == "Queen") %>%
  dplyr::select(song_id, starts_with("V")) %>%
  as.data.frame() %>%
  melt(id.vars = "song_id", variable.name = "topic", value.name = "gamma") %>%
  as.tbl()

ggplot(melted_k20, aes(x = gamma, fill = topic)) +
  geom_histogram(bins = 20) +
  facet_wrap(~topic, scale = "free")
