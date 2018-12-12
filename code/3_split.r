# Purpose: Split clean data into 70/30 train/test for logistic regression, cast full clean to dtm for lda

userArgs <- commandArgs(trailingOnly=TRUE)
NGRAMS <- as.numeric(userArgs[[1]])

source('code/library_text.r')


clean <- read_csv('data/songs_cleaned.csv')

set.seed(666)
# Split 70/30 train/test
train.idx <- sample(1:nrow(clean), size=0.7*nrow(clean))
test.idx <- which(!seq(nrow(clean)) %in% train.idx)

train <- clean[train.idx,]
test <- clean[test.idx,]

saveRDS(train, 'data/inputs/train.rds')
saveRDS(test, 'data/inputs/test.rds')

# DTM
# Unnest tokens by NGRAMS
tokens <- unnest_ngrams(train, n=NGRAMS)

# Additional cleaning on unnested tokens
# Remove numeric "tokens" greater than one digit
# NOTE: for NGRAMS>1, this removes any token with a numeric
one_digs <- grep('^[0-9]$', tokens$ngram)
any_digs <- grep('[[:digit:]]', tokens$ngram)
other_digs <- setdiff(any_digs, one_digs)
tokens <- tokens[-other_digs,]
# count tokens
tokens.count <- count(tokens, ngram, song_id)

# Cast to dtm
tokens.dtm <- cast_dtm(tokens.count, song_id, ngram, n)

# Save full dtm
saveRDS(tokens.dtm, file=paste0('data/inputs/lda/songs_n', NGRAMS, '_dtm.rds'))
