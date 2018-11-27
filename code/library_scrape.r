# Library for scraping www.lyrics.com

library(rvest)
library(xml2)
library(httr)


# FUNCTIONS
parse_site_content <- function(url) {
    # Retrieve url request content, parse html content as utf-8 text

    response <- httr::GET(url)
    content <- httr::content(x=response, as='text', encoding='utf-8')
    parsed_html <- xml2::read_html(content)

    return(parsed_html)
}


scrape_gen <- function(parsed_html, xpath_str) {
    # Scrape node from parsed_html given xpath

    nodes <- rvest::html_nodes(parsed_html, xpath=xpath_str)
    return( nodes )
}


scrape_href <- function(parsed_html, xpath_str) {
    # Scrape href attribute from parsed html given xpath

    nodes <- rvest::html_nodes(parsed_html, xpath=xpath_str)
    hrefs <- rvest::html_attr(nodes, name='href')
    return( hrefs )
}


clean_genreStyles <- function(song_meta) {
    # Cleans scraped song genre/style data
    # @param song_meta: list of scraped song genres/styles

    clean_genreStylesHelper <- function(inner_list) {
        # Helper function: finds indices that begin with alpha chr

        indices <- sapply(inner_list, function(string) grepl('^[[:alpha:]]+', string))
        return( indices )
    }

    cleaned <- lapply(song_meta, function(x) x[clean_genreStylesHelper(x)])
    text <- lapply(cleaned, as.character)

    # Songs w/ no genre/style are empty chr vectors
    missings <- sapply(text, function(x) length(x)==0)
    text[missings] <- c('None')

    return( text )
}
