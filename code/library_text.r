# Library of functions for text analysis

suppressMessages(library(tidyverse))
library(tidytext)
library(tm)
library(topicmodels)


# GLOBALS
data(stop_words)
myStopWords <- rbind(stop_words, data.frame(word=tm::stopwords('spanish'), lexicon='tm::spanish'))


# FUNCTIONS
count_ngrams <- function(dt, n=2, spanish=TRUE, stopWords=myStopWords) {
    # Unnest and count ngrams

    word_vars <- c(paste0('word', (1:n)))

    if (spanish) {
        stops <- stopWords
    } else {
        stops <- stopWords %>% filter(lexicon!='tm::spanish')
    }

    dt %>% unnest_tokens(ngram, lyrics, token='ngrams', n=n) %>%
        separate(ngram, word_vars, sep=' ') %>%
        filter_at(.vars=word_vars, .vars_predicate=any_vars(!. %in% stops)) %>%
        unite(ngram, !!word_vars, sep=' ') %>%
        count(ngram, sort=TRUE)

    return(dt)
}


plot_beta_spread <- function(lda, n) {
    # Plot beta spread of lda model

    topics_per_word <- tidy(lda, matrix='beta')

    top_terms <- topics_per_word %>%
        group_by(topic) %>%
        top_n(n, beta) %>%
        ungroup() %>%
        arrange(topic, -beta) %>%
        mutate(term=reorder(term, beta))

    p <- ggplot(top_terms, aes(term, beta, fill=factor(topic))) +
        geom_col(show.legend=FALSE) +
        facet_wrap(~ topic, scale='free') +
        coord_flip()

    return(p)
}
