# Purpose: LDA

start_time <- Sys.time()

# Parse user args
userArgs <- commandArgs(trailingOnly=TRUE)
# Hardcode userArgs until properly setup to be passed in
NGRAMS <- as.numeric(userArgs[[1]])
DOCUMENT <- as.character(userArgs[[2]])
Ks <- as.character(userArgs[[3]])

source('code/library_text.r')

# LDA Settings
bad.seed <- 666
ks <- sapply(strsplit(Ks, ';')[[1]], as.numeric, USE.NAMES=FALSE)


###################
# Count tokens within document
ngram.dtm <- readRDS(paste0('data/inputs/', DOCUMENT, '_n', NGRAMS, '_dtm.rds'))

# Filename stubs for model outputs
model_stub <- paste0('models/lda/lda_', DOCUMENT, '_ngram', NGRAMS, '_k')
plot_stub <- paste0('dump/lda_', DOCUMENT, '_ngram', NGRAMS, '_k')

# LDA Modeling
cl <- register_parallel()

foreach (k=ks, .packages=c('magrittr', 'dplyr', 'tidytext', 'topicmodels', 'ggplot2')) %dopar% {
     
    lda <- LDA(ngram.dtm, k=k, control=list(seed=bad.seed))
    # Save LDA model
    saveRDS(object=lda, file=paste0(model_stub, k, '.rds'))
    # Save beta spread plot
    p <- plot_beta_spread(lda, n=15)
    ggsave(paste0(plot_stub, k, '.png'), p, dpi=320)
}

try(stopCluster(cl), silent=TRUE)

print(Sys.time() - start_time)
