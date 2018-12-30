# Sing A Song
Classifying song genres from Latent Dirichlet Allocation predicted topics.

### Authors
Alan Chen & Mac Tan

### Date
Fall 2018

## Code
- library_scrape.r - functions for scraping data
- library_text.r - functions for bag-of-words text processing
- library_model.r - functions for modeling
- 1a_scrape.r - scrape data from Lyrics.com
- 1b_compile.r - compile scraped lyrics data and metadata into one csv
- 1c_combine.r - combine all scraped data into one csv
- 2_clean.r - clean combined scraped data
- hpc/lda.sh - parallelized lda modeling
    + 3a_cast_dtm.r - unnest cleaned data into tokens, cast to dtm
    + 3b_lda.r - run LDA model on dtm
- 4_lda_post_slit.r - merge LDA model posterior document-topic probability distributions with cleaned data
- 5_lda_logistic.r - run logistic regression models using LDA document-topic probability features
- visuals.r - generate plots/visuals for report

Note: scripts not described still in progress
