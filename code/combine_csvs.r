# Purpose: Combine partial scrapes

library(data.table)
library(parallel)
library(doParallel)
# Register half the number of cores available
num_cores <- parallel::detectCores()
if (num_cores > 3) {
    cl <- parallel::makeCluster(num_cores - 1)
    doParallel::registerDoParallel(cl)
}

partial_files <- system2('ls', 'data/clean/songData_*.csv', stdout=TRUE)


# Read, clean, and compile data into one data.table
combined <- rbindlist(
    foreach (f=partial_files, .packages=c('data.table')) %dopar% {

    temp <- data.table::fread(f)
    temp
})

write.csv(combined, file='data/songData_combined.csv', row.names=FALSE)
