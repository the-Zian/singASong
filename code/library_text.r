# Library of functions for text analysis

pckgs <- c('tidyverse', 'tidytext', 'tm', 'topicmodels', 'parallel', 'doParallel')
sapply(pckgs, function(pckg){
    suppressMessages(library(pckg, character.only=TRUE, logical.return=TRUE))
})


# GLOBALS
data(stop_words)
stop_words$lexicon <- paste0(stop_words$lexicon, '::english')
song_stops <- read_csv('data/inputs/song_stops.csv')
song_stops$lexicon <- 'custom'
stop_words <- rbind(stop_words,
    data.frame(word=tm::stopwords('spanish'), lexicon='tm::spanish'),
    data.frame(word=stopwords('french'), lexicon='tm::french'),
    data.frame(word=stopwords('portuguese'), lexicon='tm::portuguese'),
    data.frame(word=stopwords('italian'), lexicon='tm::italian'),
    data.frame(word=stopwords('german'), lexicon='tm::german'),
    song_stops
    )



# FUNCTIONS
register_parallel <- function(num_cores=NA) {
    # Setup cores for parallel computing

    if (is.na(num_cores)) {
        num_cores <- parallel::detectCores()
}
cl <- parallel::makeCluster(num_cores)
doParallel::registerDoParallel(cl)
print(paste0('Registered ', (num_cores), ' cores for parallel computing'))

    return(cl)
}


unnest_ngrams <- function(dt, n=2, langs=NA, stopWords=stop_words) {
    #` Unnest ngrams, removing stop words and punctuation
    #` @param dt Cleaned lyrics data
    #` @param n n-grams
    #` @param languages Stop word languages to removes
    #` @param stopWords Dictionary of stopwords

    languages <- c('english', 'custom', 'spanish', 'french', 'portuguese', 'italian', 'german')

    if (is.na(langs)) {
        langs <- languages
    } else if (!all(langs %in% languages)) {
        stop('language can only be [english, spanish, french, portuguese, italian, german, custom]')
    } else {
        pattern <- paste0(langs, collapse='|')
        stopWords <- filter(stopWords, any(!!languages %in% lexicon))
    }

    word_vars <- c(paste0('word', (1:n)))

    dt <- dt %>%
        unnest_tokens(ngram, lyrics, token='ngrams', n=n) %>%
        separate(ngram, word_vars, sep=' ') %>%
        mutate_at(.vars=word_vars, .fun=tolower) %>%
        filter_at(.vars=word_vars, .vars_predicate=all_vars(!. %in% stopWords$word)) %>%
        mutate_at(.vars=word_vars, .funs=gsub, pattern='[[:punct:]]', replacement='') %>%
        filter_at(.vars=word_vars, .vars_predicate=all_vars(nchar(.)>0)) %>%
        filter_at(.vars=word_vars, .vars_predicate=all_vars(!. %in% stopWords$word)) %>%
        drop_na(!!word_vars) %>%
        unite(ngram, !!word_vars, sep=' ')

    return(dt)
}


plot_beta_spread <- function(lda, n) {
    # Plot beta spread of lda model

    topics_per_word <- tidy(lda, matrix='beta')
  
    top_terms <- topics_per_word %>%
    group_by(topic) %>%
    top_n(n, beta) %>%
    ungroup() %>%
    arrange(topic, beta) %>%
    mutate(plot_order=row_number())
  
    p <- ggplot(top_terms, aes(plot_order, beta, fill=factor(topic))) +
        geom_col(show.legend=FALSE) +
        facet_wrap(~ topic, scale='free') +
        coord_flip() +
        scale_x_continuous(breaks=top_terms$plot_order, labels=top_terms$term, expand=c(0,0)) +
        theme_minimal() +
        theme(axis.text=element_text(size=8))
  
    return(p)
}
