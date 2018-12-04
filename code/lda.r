# Purpose: LDA

library(tidyverse)
library(tidytext)
library(tm)
library(topicmodels)


# Load stop words
data(stop_words)
# Remove stop words
stop_words <- rbind(stop_words, data.frame(word=tm::stopwords('spanish'), lexicon='tm'))

# Read cleaned, combined data
raw <- read_csv('data/songs_cleaned.csv')
lyrics <- raw %>%
    mutate(decade=floor(year/10)*10)
lyrics <- lyrics %>%
    mutate(song_id=row_number()) %>%
    group_by(artist) %>%
    mutate(artist_id=as.numeric(as.factor(artist))) %>%
    ungroup()

# Unnest tokens
songs <- lyrics %>% unnest_tokens(word, lyrics, token='words')
songs <- anti_join(songs, stop_words, by='word')
# Remove punctuation
songs <- mutate(songs, word=gsub('[[:punct:]]', '', word))
songs <- filter(songs, word!='')
# Remove digits (except for words that are only 1 digit)
one_digs <- grep('^[0-9]$', songs$word)
any_digs <- grep('[[:digit:]]', songs$word)
other_digs <- setdiff(any_digs, one_digs)
songs <- songs[-other_digs,]


###################
# By song analysis
# Count words,
song_words <- count(songs, word, song_id)
# Cast to dtm
songs_dtm <- cast_dtm(song_words, song_id, word, n)

# LDA MODELS
lda1 <- LDA(songs_dtm, k=5, control=list(seed=666))

lda1_beta_spread <- plot_beta_spread(lda1, 10)
ggsave('dump/lda1_beta_spread.png', lda1_beta_spread)


###################
# By artist analysis
artist_words <- count(songs, word, artist_id)
# Cast to dtm
artists_dtm <- cast_dtm(artist_words, artist_id, word, n)

# LDA
lda2 <- LDA(artists_dtm, k=2, control=list(seed=666))

lda2_beta_spread <- plot_beta_spread(lda2, 10)
ggsave('dump/lda2_beta_spread.png', lda2_beta_spread)


###################
# Bigrams
bigrams <- count_ngrams(lyrics, n=2, spanish=TRUE)
bigram_counts <- count(bigrams, ngram, song_id)

bigrams_dtm <- cast_dtm(bigram_counts, song_id, ngram, n)
lda3 <- LDA(bigrams_dtm, song_id, ngram, n)
print('hi')

