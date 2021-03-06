# Purpose: Scrape lyrics from www.lyrics.com.
#   Scrape all pages from all genres, then scrape all song urls from each page


start <- Sys.time()
print(start)


# Parse command args
userArgs <- commandArgs(trailingOnly=TRUE)

# Source scraping library
source('code/library_scrape.r', echo=FALSE)


# Url of all genre-pages
url_base <- "https://www.lyrics.com/genre/Hip%20Hop;Jazz;Latin;Brass%20__%20Military;Blues;Children's;Classical;Electronic;Folk,%20World,%20__%20Country;Funk%20--%20Soul;Non-Music;Pop;Reggae;Rock;Stage%20__%20Screen"

# NOTE: 52022 pages total, last page is eh...
if (length(userArgs)==0) {
    urls_pages <- sapply(seq(52021), function(p) paste0(url_base, '&p=', p))
    pg_start <- 1
    pg_end <- 52021
} else {
    # Scrape only specified pages
    pg_start <- userArgs[[1]]
    pg_end <- userArgs[[2]]

    urls_pages <- sapply(seq(from=pg_start, to=pg_end), function(p) paste0(url_base, '&p=', p))
}


# Parse html for all pages
parsed_htmls <- lapply(urls_pages, parse_site_content)


###################
# Scrape genre pages
# xpath to all song/album/artist meta-data per page
xpth <- '//*[@id="content-body"]/div/div[position()>=3 and position()<=14]/div/p//text()'
# 3 elements per song
song_metas <- lapply(parsed_htmls, function(p) scrape_gen(p, xpth))

# Check for any pages with missing song meta data; just drop those pages from analysis
drop.idx <- which(sapply(song_metas, length) != 72)
if (length(drop.idx) > 0) {
    report_diagnostics(drops=drop.idx, start_page=pg_start, urls=urls_pages)
    song_metas <- song_metas[-drop.idx]
    parsed_htmls <- parsed_htmls[-drop.idx]
}

# xpath to song url
xpth <- '//*[@id="content-body"]/div/div[position()>=3 and position()<=14]/div/p[1]//a'
song_urls <- lapply(parsed_htmls, function(p) scrape_href(p, xpth))
song_url_base <- "https://www.lyrics.com"
song_urls_full <- lapply(unlist(song_urls), function(url) paste0(song_url_base, url))
song_urls_full <- unlist(song_urls_full)


###################
# Scrape each song lyric pages
song_urls_parsed <- lapply(song_urls_full, parse_site_content)

# Song year
xpth <- '//*[@id="content-body"]//div[contains(@class,"artist-meta")]//div[contains(@class,"lyric-details")]/dl/dd//text()'
song_years <- lapply(song_urls_parsed, function(p) scrape_gen(p, xpth))
song_years_cleaned <- lapply(song_years, function(x) as.numeric(as.character(x[1])))
missings <- sapply(song_years_cleaned, function(x) length(x)==0)
song_years_cleaned[missings] <- c(NA)

# Lyrics
# xpath for lyrics
xpth <- '//*[@id="lyric-body-text"]'
song_lyrics <- lapply(song_urls_parsed, function(p) scrape_gen(p, xpth))
song_lyrics_cleaned <- lapply(song_lyrics, as.character)
# Remove all html tags
ptrn <- '(<.*?>)'
song_lyrics_cleaned <- lapply(song_lyrics, function(lyric) gsub(ptrn, '', lyric))
# Remove all carriage returns/newlines/etc.
ptrn <- '[\\\r\\\n]'
song_lyrics_cleaned <- lapply(song_lyrics_cleaned, function(lyric) gsub(ptrn, ' ', lyric))
# Replace lyric-less songs with empty string
missings <- sapply(song_lyrics_cleaned, function(x) length(x)==0)
song_lyrics_cleaned[missings] <- c('')

# Genres
xpth <- '//*[@id="content-body"]/div/div/div[@class="lyric-infobox clearfix"][2]//div[@class="col-sm-6"][1]/div//text()'
song_genres <- lapply(song_urls_parsed, function(p) scrape_gen(p, xpth))
song_genres_cleaned <- clean_genreStyles(song_genres)

# Styles
xpth <- '//*[@id="content-body"]/div/div/div[@class="lyric-infobox clearfix"][2]//div[@class="col-sm-6"][2]/div//text()'
song_styles <- lapply(song_urls_parsed, function(p) scrape_gen(p, xpth))
song_styles_cleaned <- clean_genreStyles(song_styles)


###################
# Compile
source('code/1b_compile.r')


end <- Sys.time()
print(end-start)
