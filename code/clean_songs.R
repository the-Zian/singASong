# Purpose: Clean combined scraped lyric data

if(!require(qdapTools)) {
  install.packages('qdapTools')
}
library(qdapTools)
library(stringi)
suppressMessages(library(tidyverse))

songs <- readr::read_csv('data/songData_combined.csv', locale = locale(encoding = 'LATIN1'))

songs_clean <- songs %>%
  # Remove NA lyrics
  na.omit(lyrics) %>%
  
  # Remove "live", "remix" tags
  mutate(title = gsub('[[:punct:]]live[[:punct:]]', '', title, ignore.case = TRUE),
         title = gsub('[[:punct:]]remix[[:punct:]]', '', title, ignore.case = TRUE)) %>%
  mutate(title = trimws(title, 'right')) %>%
  
  # Remove duplicate URLs
  distinct(url, .keep_all = TRUE) %>%
  
  # Remove duplicated lyrics (ignore case); keep first chronologically (this hopefully takes care of covers)
  arrange(year) %>%
  group_by(gsub('[[:punct:]]', '', tolower(lyrics))) %>%
  summarise_all(first) %>%
  ungroup() %>%
  
  # Remove duplicate song titles (ignore case) from same artist
  group_by(artist, tolower(title)) %>%
  summarise_all(first) %>%
  ungroup() %>%
  
  # De-formatted genre and style tags
  mutate(genre_lower = paste0("genre.", gsub("&amp;|/|[[:space:]]|,|-|'", '', tolower(genre))),
         genre_lower = gsub("\\|", "\\|genre.", genre_lower),
         style_lower = paste0("style.", gsub("&amp;|/|[[:space:]]|,|-|'", '', tolower(style))),
         style_lower = gsub("\\|", "\\|style.", style_lower)) %>%
  
  dplyr::select(artist, year, album, title, genre, genre_lower, style, style_lower, lyrics, url, scrape_dt)

# One-hot encode genres
genre_dummies <- qdapTools::mtabulate(str_split(songs_clean$genre_lower, '\\|'))
style_dummies <- qdapTools::mtabulate(str_split(songs_clean$style_lower, '\\|'))
songs <- cbind(songs_clean, genre_dummies, style_dummies)

write.csv(songs, file = 'data/songs_cleaned.csv', row.names = FALSE)
