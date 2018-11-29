# Purpose: Compile scraped song meta data [title, album, artist], lyrics, genre, style


library(tidyverse)


###################
# Compile

# Unlist song urls
urls <- unlist(song_urls_full)

# Unlist song metadata into one vector
song_metas_full <- unlist(lapply(song_metas, function(x) as.character(x)))

artists <- song_metas_full[seq(3,length(song_metas_full), by=3)]
albums <- song_metas_full[seq(2,length(song_metas_full), by=3)]
titles <- song_metas_full[seq(1,length(song_metas_full), by=3)]
years <- unlist(song_years_cleaned)

# Unlist song lyrics
lyrics <- unlist(song_lyrics_cleaned)

# Collapse then unlist genres and styles
genres <- sapply(song_genres_cleaned, function(x) paste0(x, collapse=' | '))
styles <- sapply(song_styles_cleaned, function(x) paste0(x, collapse=' | '))

songData <- tibble(artist=artists, album=albums, year=years, title=titles,
    lyrics=lyrics,
    genre=genres, style=styles,
    url=urls, scrape_dt=timestamp)


###################
# Save data
if (length(userArgs)==0) {
    filename <- 'data/songData_full.csv'
} else {
    filename <- paste0('data/clean/songData_', pg_start, '_', pg_end, '.csv')
}
write.csv(songData, file=filename, row.names=FALSE)
