# Purpose: Generate LDA posterior probabilities

test <- readRDS('data/inputs/test.rds')

test <- test %>% mutate(song_id=row_number())
test_words <- unnest_ngrams(test, n=1)
one_digs <- grep('^[0-9]$', test_words$ngram)
any_digs <- grep('[[:digit:]]', test_words$ngram)
other_digs <- setdiff(any_digs, one_digs)
test_words <- test_words[-other_digs,]
# count words
test_words.count <- count(test_words, ngram, song_id)
test_words.dtm <- cast_dtm(test_words.count, song_id, ngram, n)

test.post <- posterior(ldak20, newdata=test_words.dtm)
post.words <- colnames(test.post[[1]])

