# Purpose: CTM


# Parse user args
userArgs <- commandArgs(trailingOnly=TRUE)

source('code/library_text.r')

# LDA Settings
bad.seed <- 666
ks <- seq(4, 10, by=2)

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
# CTM
if (exists('cl')) {
    foreach (k=ks, .packages=c('magrittr', 'dplyr', 'tidytext', 'topicmodels', 'ggplot2')) %dopar% {
        ctm <- CTM(song.words.dtm, k=k, control=list(seed=bad.seed))

        saveRDS(object=ctm, file=paste0('models/ctm/ctm_song_word_k', k, '.rds'))
        
        p <- plot_beta_spread(ctm, n=10)
        ggsave(paste0('dump/ctm_song_word_k', k, '.png'), p, dpi=320)
    }
}

if (FALSE) {
# By artist
artist.words.count <- count(words, ngram, artist_id)
artist.words.dtm <- cast_dtm(artist.words.count, artist_id, ngram, n)
if (exists('cl')) {
    foreach (k=ks, .packages=c('magrittr', 'dplyr', 'tidytext', 'topicmodels', 'ggplot2')) %dopar% {
        ctm <- CTM(artist.words.dtm, k=k, control=list(seed=bad.seed))
        
        saveRDS(object=ctm, file=paste0('models/ctm/ctm_artist_word_k', k, '.rds'))

        p <- plot_beta_spread(ctm, n=10)
        ggsave(paste0('dump/ctm_artist_word_k', k, '.png'), p, dpi=320)
    }
}
}

try(stopCluster(cl), silent=TRUE)
