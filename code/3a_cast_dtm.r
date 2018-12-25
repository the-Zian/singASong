# Purpose: Cast full clean to dtm for lda

userArgs <- commandArgs(trailingOnly=TRUE)
NGRAMS <- as.numeric(userArgs[[1]])
DOCUMENT <- as.character(userArgs[[2]])
doc_id_var <- paste0(DOCUMENT, '_id')

source('code/library_text.r')

clean <- read_csv('data/songs_cleaned.csv')

# DTM
# Unnest tokens by NGRAMS
tokens <- unnest_ngrams(clean, n=NGRAMS)

# Additional cleaning on unnested tokens
# Remove numeric "tokens" greater than one digit
# NOTE: for NGRAMS>1, this removes any token with a numeric
one_digs <- grep('^[0-9]$', tokens$ngram)
any_digs <- grep('[[:digit:]]', tokens$ngram)
other_digs <- setdiff(any_digs, one_digs)
tokens <- tokens[-other_digs,]
# count tokens grouped by document
tokens.count <- count(tokens, ngram, !!doc_id_var)

# Cast to dtm
tokens.dtm <- cast_dtm(tokens.count, !!doc_id_var, ngram, n)

# Save full dtm
saveRDS(tokens.dtm, file=paste0('data/inputs/', DOCUMENT, '_n', NGRAMS, '_dtm.rds'))
