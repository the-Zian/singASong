# Purpose: Select features for BOW via Tf-Idf across genres


source('code/library_text.r')
source('code/library_model.r')


# Read in clean
clean <- read_csv('data/songs_cleaned.csv')

# Genres for analysis
genres <- c('blues', 'electronic', 'folkworldcountry', 'funksoul', 'hiphop', 'latin', 'pop', 'reggae', 'rock')

# Collapse lyrics across genres
genre_corpus <- bind_rows(
    lapply(genres, function(genre, df=clean) {
        genre_var <- paste0('genre.', genre)
        temp <- df %>% filter_at(.vars=genre_var, all_vars(.==1))
        genre_df <- data.frame(genre_id=genre, lyrics=glue::collapse(temp$lyrics, sep=' '))
    })
)

# Unnest tokens
genre_words <- unnest_ngrams(genre_corpus, n=1)
genre_words <- count(genre_words, ngram, genre_id)

# Cast to tf-idf dtm
genre_dtm <- cast_dtm(genre_words, document=genre_id, term=ngram, value=n, weighting=tm::weightTfIdf)

# Define features
genre_dtm_tidy <- tidy(genre_dtm)


# Find top words per genre

# UNIT-TEST: n=10
genre_features <- genre_dtm_tidy %>% group_by(document) %>%
    arrange(desc(count)) %>%
    slice(1:10) %>%
    plyr::rename(document=genre_id)

# Tf-Idf by songs
song_tokens <- unnest_ngrams(clean, n=1) %>%
    count(ngram, song_id)
song_tfidf_dtm <- cast_dtm(song_tokens, document=song_id, term=ngram, value=n, weighting=tm::weightTfIdf)
song_dtm_tidy <- tidy(song_tfidf_dtm)

# Inner join top feature tokens, spread wide
song_features <- left_join(song_dtm_tidy, genre_features[, 'term'], by='term') %>%
    distinct() %>%
    spread(term, count, fill=0)

# Join on genre dummies
song_feaures %>% left_join

