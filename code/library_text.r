# Library of functions for text analysis

suppressMessages(library(tidyverse))
suppressMessages(library(tidytext))
library(tm)


# GLOBALS
data(stop_words)
myStopWords <- rbind(stop_words, data.frame(word=tm::stopwords('spanish'), lexicon='tm::spanish'))


# FUNCTIONS
count_ngrams <- function(dt, n=2, spanish=TRUE) {
    # Unnest and count ngrams

    word_vars <- c(paste0('word', (1:n)))

    if (spanish) {
        stops <- myStopWords
    } else {
        stops <- myStopWords %>% filter(lexicon!='tm::spanish')
    }

    dt %>% unnest_tokens(ngram, lyrics, token='ngrams', n=n) %>%
        separate(ngram, word_vars, sep=' ') %>%
        filter_at(.vars=word_vars, .vars_predicate=any_vars(!. %in% stops)) %>%
        unite(ngram, !!word_vars, sep=' ') %>%
        count(ngram, sort=TRUE)
}
