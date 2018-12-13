# Library of functions for classification modeling

suppressMessages(library(tidyverse))
library(topicmodels)
library(glue)
library(pROC)
library(gridExtra)
library(reshape2)


# FUNCTIONS
extract_fit <- function(model) {
    # Extract proportion of deviance over null model

    summary(model)$deviance/summary(model)$null.deviance
}


makeROCtbl <- function(roc_obj) {
    ## Functions for ROC plotting
    ## Extract sensitivity and specificity from ROC objects

    roc_tbl <- tibble(Sensitivity = roc_obj$sensitivities,
        Specificity = roc_obj$specificities)
    roc_auc <- auc(roc_obj)
    return_obj <- list(roc_tbl = roc_tbl, auc = roc_auc)
  
    return(return_obj)
}


ggplotROC <- function(roc_tbl_list, k_ind, genre_ind) {
    ## Create ROC curve
  
    genre <- genres[genre_ind]
    k <- 10*k_ind
  
    ggplot(roc_tbl_list[[k_ind]][[genre_ind]]$roc_tbl, aes(x = 1 - Specificity, y = Sensitivity)) +
        geom_line() +
        labs(title = paste0(genre, ", ", "K = ", k),
         subtitle = paste0("AUC: ", roc_tbl_list[[k_ind]][[genre_ind]]$auc %>% round(3)))
}
