# Purpose: Split 70/30 train/test for classification models

suppressMessages(library(tidyverse))

clean <- read_csv('data/songs_cleaned.csv')

set.seed(666)
# Split 70/30 train/test
train.idx <- sample(1:nrow(clean), size=0.7*nrow(clean))
test.idx <- which(!seq(nrow(clean)) %in% train.idx)

clean_words <- unnest_ngrams(clean, n = 1)

train <- clean[train.idx,]
test <- clean[test.idx,]



saveRDS(train, 'data/inputs/train.rds')
saveRDS(test, 'data/inputs/test.rds')