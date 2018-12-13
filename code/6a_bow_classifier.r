# Purpose: Select features for BOW via Tf-Idf across genres


source('code/library_text.r')
library(glue)


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
genre_dtm <- cast_dtm(genre_words, document=genre_id, term=ngram, value=n)

# Define features
genre_dtm_tidy <- tidy(genre_dtm)

saveRDS(genre_dtm_tidy, file='data/inputs/genre_dtm.rds')
