# Sing A Song
Supervised machine learning predictions from song lyrics. Final project for Messy Data & Machine Learning (NYU).

### Authors
Alan Chen & Mac Tan

### Date
Fall 2018

## Purpose / Research Questions
The advent of readily available, scalable natural language processing (NLP) and supervised machine learning (ML) tools can unlock insights to curiosities in a wealth of text based domains. We believe, with the enduring popularity of music and singing in human cultures, we can begin to answer a host of questions to entertain and enlighten humanity. Given the lyrics of a song, consider:  

* Predicting the genre  
* Predicting the artist  
* Predicting the recording year

## Data
There are several datasets of song lyrics with artist, genre, and other relevant features readily available on the web.

**Sources**
We scrape song lyrics from https://www.lyrics.com, an online song lyrics database with over 1.2 million songs tagged by genre. The site contains song lyrics as well as metadata on artist, album, song title, and year (for most songs).

## Methods
For feature engineering, we will begin with a bag-of-words model on the lyric text, and possibly explore additional deep learning alternatives.

For genre classification and prediction, we plan to employ a variety of supervised ML techniques including, but not limited to:  

* Logistic regression
* Support vector machines (SVM)
* Neural networks
