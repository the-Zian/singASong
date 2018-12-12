# Library of functions for text analysis

suppressMessages(library(tidyverse))
library(tidytext)
library(tm)
library(topicmodels)
library(parallel)
library(doParallel)


# GLOBALS
data(stop_words)
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


unnest_ngrams <- function(dt, n=2, english=FALSE, stopWords=stop_words) {
  # Unnest ngrams
  # Remove stop words
  # Remove punctuation
  
  word_vars <- c(paste0('word', (1:n)))
  
  if (english) {
    stops <- stopWords %>% filter(!grepl('tm', lexicon))
  } else {
    stops <- stopWords
  }
  
  dt <- dt %>%
    unnest_tokens(ngram, lyrics, token='ngrams', n=n) %>%
    separate(ngram, word_vars, sep=' ') %>%
    mutate_at(.vars=word_vars, .fun=tolower) %>%
    filter_at(.vars=word_vars, .vars_predicate=any_vars(!. %in% stops$word)) %>%
    mutate_at(.vars=word_vars, .funs=gsub, pattern='[[:punct:]]', replacement=NA) %>%
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