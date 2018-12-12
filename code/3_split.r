# Purpose: Split data into 70/30 train and test

set.seed(666)

clean <- read_csv('data/songs_cleaned.csv')

train.idx <- sample(1:nrow(clean), size=0.7*nrow(clean))
test.idx <- which(!seq(nrow(clean)) %in% train.idx)

train <- clean[train.idx,]
test <- clean[test.idx,]

saveRDS(train, 'data/inputs/train.rds')
saveRDS(test, 'data/inputs/test.rds')
