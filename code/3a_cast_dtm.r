# Purpose: Cast full clean to dtm for lda

userArgs <- commandArgs(trailingOnly=TRUE)
NGRAMS <- as.numeric(userArgs[[1]])

source('code/library_text.r')

clean <- read_csv('data/songs_cleaned.csv')

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
