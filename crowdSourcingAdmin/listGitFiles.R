#' ----
#' title: " A script for listing files in a github repo"
#' author: "Daniel Pett"
#' date: "19/05/2016"
#' output: csv_document
#' ----
#' 

# Set working directory (for example as below)
setwd("~/Documents/research/micropasts/analysis/") #MacOSX
#setwd("C:\\micropasts\\analysis") #Windows
#setwd("micropasts/analysis") #Linux

# Create CSV directory if it does not exist
if (!file.exists('csv')){
  dir.create('csv')
}

username <- 'micropasts' #change for your username
repo <- 'MuseoEgizio1_foto' #change for your repo with photos

url <- paste('https://api.github.com/repos', username, repo, 'git/trees/master?recursive=1', sep='/')
library(httr)
req <- GET(url)
stop_for_status(req)

filelist <- unlist(lapply(content(req)$tree, "[", "path"), use.names = F)
files <- as.data.frame(filelist)

rawUrl <- paste('https://raw.githubusercontent.com', username, repo, 'master/', sep='/')
for(i in files){
  finalList <- paste(rawUrl, i, sep='')
}
data <- as.data.frame(finalList)
head(data)
# Rename column
names(data) <-c('url_b')
# Set filename
filename <- paste(repo, '.csv', sep='')

# Create CSV
write.csv(data, file=filename,row.names=FALSE, na="")
