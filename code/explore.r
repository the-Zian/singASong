# Purpose: Exploratory data analysis of scraped data

source('code/library_text.r')
library(data.table)
theme_set(theme_minimal())
library(wordcloud)
library(igraph)
library(ggraph)


###################
# Read combined scraped data
songData <- fread('data/songs_cleaned.csv')


###################
# FEATURES
songData[, decade:=floor(year/10)*10]
songData[, genre:=gsub('&amp; ', '', genre)]
songData[, genre1:=sub('^(.+?) \\|..*', '\\1', genre)]


###################
# PLOTS
ggplot(fortify(songData[lyrics!='',]), aes(x=decade)) +
geom_bar(color='black', fill='seagreen', alpha=0.6) +
scale_x_continuous(labels=seq(from=1930, to=2020, by=10), breaks=seq(from=1930, to=2020, by=10))

ggplot(fortify(songData[lyrics!='',]), aes(x=genre1)) +
geom_bar(color='black', fill='seagreen4', alpha=0.6) +
theme(axis.text.x=element_text(angle=60, hjust=1))


###################
# TIDYVERSE
songData <- fread('data/songs_cleaned.csv') %>% 
  mutate(decade=floor(year/10)*10) %>% 
  mutate(genre1=sub('^(.+?) \\|..*', '\\1', genre))

# Remove pure duplicates (identified by url)
songData2 <- distinct(songData, url, .keep_all=TRUE) %>%
  # Remove duplicates (artist, track), keep earliest song
  arrange(artist, desc(year), title) %>%
  distinct(title, artist, .keep_all=TRUE) %>%
  # Drop songs with missing lyric data
  filter(!is.na(lyrics))

songData2 %>%
  dplyr::select(starts_with("genre.")) %>%
  colMeans() %>%
  round(3)


# TEXT ANALYSIS
###################
# tokenize by word
tidySongData <- songData2 %>% 
  select(-starts_with("style.")) %>%
  unnest_tokens(word, lyrics)
data(stop_words)
tidySongDataClean <- anti_join(tidySongData, stop_words) %>% 
  anti_join(data.frame(word=tm::stopwords('spanish')))

# Marvin Gaye sentiment analysis
nrc <- sentiments %>%
    filter(lexicon=='nrc') %>%
    select(-score)
beatles <- tidySongDataClean %>%
    filter(artist=='The Beatles') %>%
    left_join(nrc)
beatles %>% count(word) %>%
    with(wordcloud(word, n, max.words=20))
queen %>% count(sentiment) %>%
    with(wordcloud(sentiment, n, max.words=20))

# word TF-IDF by genre
genre_tfidf <- tidySongDataClean %>%
    count(genre1, word) %>%
    bind_tf_idf(word, genre1, n) %>%
    arrange(desc(tf_idf)) %>%
    mutate(word=factor(word, levels=rev(unique(word))),
        genre1=factor(genre1, levels=unique(genre1)))

genre_tfidf %>% group_by(genre1) %>%
    top_n(11, tf_idf) %>%
    mutate(word=reorder(word, tf_idf)) %>%
    ungroup() %>%
    ggplot(aes(word, tf_idf, fill=genre1)) +
    geom_col(show.legend=FALSE) +
    labs(x=NULL, y='tf-idf') +
    facet_wrap(~genre1, ncol=4, scales='free') +
    coord_flip()


# tokenize by bigram
bigrams <- songData %>%
    unnest_tokens(bigram, lyrics, token='ngrams', n=2) %>%
    separate(bigram, c('word1', 'word2'), sep=' ') %>%
    filter(!word1 %in% stop_words$word, !word2 %in% stop_words$word,
        !word2 %in% data.frame(word=tm::stopwords('spanish')))
bigramsClean <- bigrams %>%
    unite(bigram, word1, word2, sep=' ')

# bigram TF-IDF by genre
genre_tfidf <- bigramsClean %>%
    count(genre1, bigram) %>%
    bind_tf_idf(bigram, genre1, n) %>%
    arrange(desc(tf_idf)) %>%
    mutate(genre1=factor(genre1, levels=unique(genre1)))

genre_tfidf %>%
    group_by(genre1) %>%
    top_n(11, tf_idf) %>%
    ungroup() %>%
    mutate(bigram=reorder(bigram, tf_idf)) %>%
    ggplot(aes(bigram, tf_idf, fill=genre1)) +
    geom_col(show.legend=FALSE) +
    labs(x=NULL, y='tf-idf') +
    facet_wrap(~genre1, ncol=4, scales='free') +
    coord_flip()

# Bigram network graphs
bigramGraph <- bigrams %>%
    count(word1, word2, sort=TRUE) %>%
    filter(n>20) %>%
    arrange(desc(n)) %>%
    graph_from_data_frame()

plot(induced_subgraph(bigramGraph, vids=c(1:20)))
plot(subgraph.edges(bigramGraph, eids=c(1:20)))

g <- 'Hip Hop'
bigramGraphG <- bigrams %>% filter(genre1==g) %>%
    count(word1, word2, sort=TRUE) %>%
    filter(n>20) %>%
    arrange(desc(n)) %>%
    graph_from_data_frame()
plot(subgraph.edges(bigramGraphG, eids=c(1:20)))


set.seed(666)
a <- grid::arrow(type = "closed", length = unit(.15, "inches"))
ggraph(bigramGraphG, layout = "fr") +
    geom_edge_link(aes(edge_alpha = n), show.legend = FALSE,
                 arrow = a, end_cap = circle(.07, 'inches')) +
    geom_node_point(color = "lightblue", size = 5) +
    geom_node_text(aes(label = name), vjust = 1, hjust = 1) +
    theme_void()


