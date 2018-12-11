# Purpose: LDA

start_time <- Sys.time()

# Parse user args
userArgs <- commandArgs(trailingOnly=TRUE)
# Hardcode userArgs until properly setup to be passed in
NGRAMS <- userArgs[[1]]
SONG <- userArgs[[2]]
ARTIST <- userArgs[[3]]

source('code/library_text.r')

# LDA Settings
bad.seed <- 666
ks <- seq(2, 10, by=2)

###################
# Format data for LDA (unnest, cast to dtm)
# Check if unnested data already saved
unnested_data <- paste0('data/inputs/unnested_n', NGRAMS, '.rds')

if (!file.exists(unnested_data)) {
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

    # Unnest tokens by NGRAMS
    words <- unnest_ngrams(lyrics, n=NGRAMS)
    saveRDS(words, file=unnested_data)
} else {
    words <- readRDS(unnested_data)
}

###################
# Count tokens within song
if (SONG) {
    # Check if song_dtm exists
    song_dtm <- paste0('data/inputs/dtm_song_n', NGRAMS, '.rds')

    if (!file.exists(song_dtm)) {
        # Remove numeric "words" greater than one digit
        one_digs <- grep('^[0-9]$', words$ngram)
        any_digs <- grep('[[:digit:]]', words$ngram)
        other_digs <- setdiff(any_digs, one_digs)
        words <- words[-other_digs,]
        # count words
        song.words.count <- count(words, ngram, song_id)
        # cast to dtm
        song.words.dtm <- cast_dtm(song.words.count, song_id, ngram, n)
        saveRDS(song.words.dtm, file=song_dtm)
    } else {
        song.words.dtm <- readRDS(song_dtm)
    }

    # Filename stubs for model outputs
    model_stub <- paste0('models/lda/lda_song_ngram', NGRAMS, '_k')
    plot_stub <- paaste0('dump/lda_song_ngram', NGRAMS, '_k')

    # LDA Modeling
    cl <- register_parallel()

    foreach (k=ks, .packages=c('magrittr', 'dplyr', 'tidytext', 'topicmodels', 'ggplot2')) %dopar% {
        lda <- LDA(song.words.dtm, k=k, control=list(seed=bad.seed))
        # Save LDA model
        saveRDS(object=lda, file=paste0(model_stub, k, '.rds'))
        # Save beta spread plot
        p <- plot_beta_spread(lda, n=15)
        ggsave(paste0(plot_stub, k, '.png'), p, dpi=320)
    }

    try(stopCluster(cl), silent=TRUE)
}

###################
# Count tokens within artist
if (ARTIST) {
    # Check if artist_dtm exists
    artist_dtm <- paste0('data/inputs/dtm_artist_n', NGRAMS, '.rds')

    if (!file.exists(artist_dtm)) {
        # count words
        artist.words.count <- count(words, ngram, artist_id)
        # cast to dtm
        artist.words.dtm <- cast_dtm(artist.words.count, artist_id, ngram, n)
        saveRDS(artist.words.dtm, file=artist_dtm)
    } else {
        artist_words.dtm <- readRDS(artist_dtm)
    }

    # Filename stubs for model outputs
    model_stub <- paste0('models/lda/lda_artist_ngram', NGRAMS, '_k')
    plot_stub <- paste0('dump/lda_artist_ngram', NGRAMS, '_k')

    # LDA Modeling
    cl <- register_parallel()

    foreach (k=ks, .packages=c('magrittr', 'dplyr', 'tidytext', 'topicmodels', 'ggplot2')) %dopar% {
        lda <- LDA(song.words.dtm, k=k, control=list(seed=bad.seed))
        # Save LDA model
        saveRDS(object=lda, file=paste0(model_stub, k, '.rds'))
        # Save beta spread plot
        p <- plot_beta_spread(lda, n=15)
        ggsave(paste0(plot_stub, k, '.png'), p, dpi=320)
    }

    try(stopCluster(cl), silent=TRUE)
}


print(Sys.time() - start_time)
