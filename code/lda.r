# Purpose: LDA

library(tidyverse)
library(tidytext)
library(tm)
library(topicmodels)


# Load stop words
data(stop_words)
# Remove stop words
# stop_words <- rbind(data.frame(word=tm::stopwords('spanish'), lexicon='tm'), data.frame(word=tm::stopwords('italian'), lexicon='tm'))

# Read cleaned, combined data
songs <- read_csv('data/songs_cleaned.csv')
songs <- mutate(songs, decade=floor(year/10)*10)
songs <- mutate(songs, id=row_number())

# Unnest tokens
songs <- songs %>% unnest_tokens(word, lyrics, token='words')
songs <- anti_join(songs, stop_words)
# Remove punctuation
songs <- mutate(songs, word=gsub('[[:punct:]]', '', word))
songs <- filter(songs, word!='')
# Remove digits (except for words that are only 1 digit)
one_digs <- grep('^[0-9]$', songs$word)
any_digs <- grep('[[:digit:]]', songs$word)
other_digs <- setdiff(any_digs, one_digs)
songs <- songs[-other_digs,]
# Count words, 
song_words <- count(songs, word, id)

# Cast to dtm
songs_dtm <- cast_dtm(song_words, id, word)