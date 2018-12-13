#Purpose: Generate visuals


library(data.table)
suppressMessages(library(tidyverse))
library(reshape2)
library(stringr)
library(wesanderson)
library(RColorBrewer)


# Read in cleaned data
songs <- read_csv('data/songs_cleaned.csv')


###################
# PLOTS
theme_set(theme_minimal())

tol18rainbow=c("#771155", "#AA4488", "#CC99BB", "#114477", "#4477AA", "#77AADD", "#117777", "#44AAAA", "#77CCCC", "#777711", "#AAAA44", "#DDDD77", "#774411", "#AA7744", "#DDAA77", "#771122", "#AA4455", "#DD7788")

# Stacked bar plot of genres by decade
songs <- songs %>% mutate(decade=floor(year/10)*10)
# Calculate number of genres per decade
genre_vars <- names(songs)[grep('^genre\\.', names(songs))]
genres <- songs %>% select(decade, !!genre_vars) %>%
    group_by(decade) %>%
    summarise_at(.vars=genre_vars, .funs=sum) %>%
    melt(id.vars='decade', measure.vars=genre_vars, variable.name='genre') %>%
    group_by(decade) %>%
    mutate(n=sum(value), value=value/n) %>%
    mutate(genre=str_replace(genre, 'genre\\.', '')) 

genre_labels <- c('Blues', 'Brass/Military', 'Childrens', 'Electronic', 'Folk/World/Country', 'Funk/Soul', 'Hip-Hop', 'Jazz', 'Latin', 'None', 'Non-music', 'Pop', 'Reggae', 'Rock', 'Stage/Screen')

p <- ggplot(genres, aes(decade, value, fill=genre)) +
    geom_col(alpha=0.8) +
    scale_x_continuous(labels=seq(1930,2020,10), breaks=seq(1930,2020,10)) +
    scale_fill_manual(name='Genre', values=tol18rainbow, labels=genre_labels) +
    labs(x='', y='', title='Genre Proportions', subtitle='Genres are not mutually exclusive')
ggsave('report/genre_decade.png', p, device='png', dpi=320)
