# Purpose: LDA

source('code/library_text.r')


evil.seed <- 666
cl <- register_parallel()
# Read cleaned, combined data
raw <- read_csv('data/songs_cleaned.csv')
lyrics <- raw %>%
    mutate(decade=floor(year/10)*10)
# Create ids
lyrics <- lyrics %>%
    mutate(song_id=row_number()) %>%
    group_by(artist) %>%
    mutate(artist_id=as.numeric(as.factor(artist))) %>%
    ungroup()


###################
# MODELS

# Words
###################
# By song
words <- unnest_ngrams(lyrics, n=1)
# Remove numeric "words" greater than one digit
one_digs <- grep('^[0-9]$', words$ngram)
any_digs <- grep('[[:digit:]]', words$ngram)
other_digs <- setdiff(any_digs, one_digs)
words <- words[-other_digs,]
# count words
song.words.count <- count(words, ngram, song_id)
# cast to dtm
song.words.dtm <- cast_dtm(song.words.count, song_id, ngram, n)
# LDA
foreach (k=seq(2,10,by=2), .packages=c('magrittr', 'dplyr', 'tidytext', 'topicmodels', 'ggplot2')) %dopar% {
    lda <- LDA(song.words.dtm, k=k, control=list(seed=evil.seed))
    plot_beta_spread(lda, 10)
    ggsave(paste0('dump/lda_song_word_k', k, '.png'), dpi='retina')
}

# By artist
artist.words.count <- count(words, ngram, artist_id)
artist.words.dtm <- cast_dtm(artist.words.count, artist_id, ngram, n)
foreach (k=seq(2,10,by=2), .packages=c('magrittr', 'dplyr', 'tidytext', 'topicmodels', 'ggplot2')) %dopar% {
    lda <- LDA(artist.words.dtm, k=k, control=list(seed=evil.seed))
    plot_beta_spread(lda, 10)
    ggsave(paste0('dump/lda_artist_word_k', k, '.png'), dpi='retina')
}


stopCluster(cl)

