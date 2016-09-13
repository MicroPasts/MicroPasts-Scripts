#' ----
#' title: " A script for manipulation of the Magic Mountain, Denver Museum crowdsourcing project"
#' author: "Daniel Pett"
#' date: "05/23/2016"
#' output: csv_document
#' ----

# Set working directory (for example as below)
setwd("~/Documents/research/micropasts/analysis/wgs/") #MacOSX
#setwd("C:\\micropasts\\analysis\\wgs") #Windows
#setwd("micropasts/analysis") #Linux

# Create CSV directory if does not exist
if (!file.exists('csv')){
  dir.create('csv')
}

# Create archives directory if does not exist
if (!file.exists('archives')){
  dir.create('archives')
}

# Create JSON folder 
if (!file.exists('json')){
  dir.create('json')
}

# Add necessary libraries
library(jsonlite)
library(stringr)

# Load user data
# http://crowdsourced.micropasts.org/admin/users/export?format=csv (when logged in as admin)
# This saves as all_users.csv and put this in the csv folder

users <- read.csv('csv/all_users.csv', header=TRUE)
users <- users[,c("id","fullname","name")]

# Set the project name
project <- 'magicMountain'

# Set the base url of the application
baseUrl <- 'http://crowdsourced.micropasts.org/project/'

# Set the task runs api path
tasks <- '/tasks/export?type=task&format=json'

# Form the export url
url <- paste(baseUrl,project, tasks, sep='')
archives <- paste('archives/',project,'Tasks.zip', sep='')

# Import tasks from json, this method has changed due to coding changes by SciFabric to their code
download.file(url,archives)
unzip(archives)
taskPath <- paste('json/', project, '.json', sep='')
rename <- paste(project, '_task.json', sep='')
file.rename(rename, taskPath)

# Read json files
which(lapply(readLines(taskPath), function(x) tryCatch({jsonlite::fromJSON(x); 1}, error=function(e) 0)) == 0)
trT <- fromJSON(paste(readLines(taskPath), collapse=""))
trT <- cbind(trT$id,trT$info)
trTfull <- trT

# extract just task id and image URL, title
trT <- trT[,c(1,2)]
names(trT) <- c("taskID","pdfPath")

# Import task runs from json
taskruns <- '/tasks/export?type=task_run&format=json'
urlRuns <- paste(baseUrl,project, taskruns, sep='')
archiveRuns <-paste('archives/', project, 'TasksRun.zip', sep='')
download.file(urlRuns,archiveRuns)
unzip(archiveRuns)
taskruns <- paste('json/', project, '_task_run.json', sep='')
renameRuns <-paste(project, '_task_run.json', sep='')   
file.rename(renameRuns, taskruns)

# Read the JSON
json <- fromJSON(taskruns)

# Drop the broken entries (To reformat db side)
json <- json[-(1:5),]
head(json)

# Read the transcription data
transcriptionEntry <- json$info

# Run lapply functions to unlist the data in this column
tf <- lapply(transcriptionEntry, function(trans)
{
  unlist(trans[[1]])
})

tg <- lapply(tf, function(trans)
{
  data.frame(unlist(trans))
})
# Bind the data together
tg <-do.call(rbind,tg)

tc <- lapply(transcriptionEntry, function(trans)
{
  unlist(trans[[2]])
})
td <- lapply(tc, function(trans)
{
  data.frame(unlist(trans))
})
# Bind the data together
td <-do.call(rbind,td)

# Order the data
tg <- tg[order(tg$X1),]
# Set the names for the data
names(tg) <- c("CatalogueNumber",  'North', 'East', 'L', 'Depth (low)', 'FS No.', 'S No.', 'Description')

# Order data by catalogue number
finalData <- tg[order(tg$CatalogueNumber),]

# NA the null values

# Break up data with new line between task runs
trTr1 <- finalData[which(is.na(finalData$taskID)), ] #blank df to fill

newrow <- rep(NA,ncol(finalData))

tail(finalData, 1000)

# Write CSV file output
csvname <- paste('csv/', project, '.csv', sep='')
write.csv(finalData, file=csvname,row.names=FALSE, na="")
