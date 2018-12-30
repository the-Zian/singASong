# Purpose: Clean combined scraped lyric data

library(qdapTools)
suppressMessages(library(tidyverse))

songs <- readr::read_csv('data/songData_combined.csv', locale=locale(encoding='LATIN1'))
if (file.exists('data/songData_combined_mac.csv')) {
    songs2 <- readr::read_csv('data/songData_combined_mac.csv', local=locale(encoding='LATIN1'))
    songs <- rbind(songs, songs2)
    rm(songs2)
    gc()
}

songs_clean <- songs %>%
    # Remove NA lyrics
    na.omit(lyrics) %>%
    # Remove "live", "remix" tags
    mutate(title = gsub('[[:punct:]]live[[:punct:]]', '', title, ignore.case = TRUE),
        title = gsub('[[:punct:]]remix[[:punct:]]', '', title, ignore.case = TRUE)) %>%
    mutate(title = trimws(title, 'right')) %>%
    # Remove duplicate URLs
    arrange(year) %>%
    distinct(url, .keep_all = TRUE) %>%
    # Remove duplicated lyrics (ignore case); keep first chronologically (this hopefully takes care of covers)
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
        style_lower = gsub("\\|", "\\|style.", style_lower),
        decade=floor(year/10)*10) %>%
    select(artist, year, decade, album, title, genre, genre_lower, style, style_lower, lyrics, url, scrape_dt) %>%
    # Generate ids
    mutate(song_id=row_number()) %>%
    mutate(artist_id=as.numeric(as.factor(artist)))


# One-hot encode genres
genre_dummies <- qdapTools::mtabulate(str_split(songs_clean$genre_lower, '\\|'))
style_dummies <- qdapTools::mtabulate(str_split(songs_clean$style_lower, '\\|'))

songs_clean <- cbind(songs_clean, genre_dummies, style_dummies)

write.csv(songs_clean, file = 'data/songs_cleaned.csv', row.names = FALSE)
