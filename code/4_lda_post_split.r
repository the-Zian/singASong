# Purpose: Generate LDA posterior probabilities; merge with song data; split 70/30 train/test

suppressMessages(library(tidyverse))
library(topicmodels)


# Read in LDA model objects
ks <- seq(5) * 10
lda_rds <- paste0('models/lda/', ks, '.rds')
ldas <- lapply(lda_rds, readRDS)
gammas <- vector('list', length(ks))
# Pull posterior gammas, cbind song ids
for (i in 1:length(ks)) {
    gamma <- ldas[[i]]@gamma %>%
        as.data.frame %>%
        as.tbl()
    gammas[[i]] <- cbind(ldas[[i]]@documents %>% as.numeric(), gamma)
}
gammas <- lapply(gammas, function(df) {names(df)[1] <- 'song_id'; return(df)})

# Merge gammas with cleaned data
clean <- readRDS('data/songs_cleaned.csv')
datas <- lapply(gammas, function(df) {
    df <- left_join(clean, df, by='song_id')
})

# Split 70/30 train/test
set.seed(666)
train.idx <- sample(1:nrow(clean), size=0.7*nrow(clean))
test.idx <- which(!seq(nrow(clean)) %in% train.idx)

trains <- lapply(datas, function(df) df[train.idx,])
tests <- lapply(datas, function(df) df[test.idx,])

# Save
saveRDS(trains, file='data/inputs/train.rds')
saveRDS(tests, file='data/inputs/test.rds')
