#' ----
#' title: " A script for downloading data for Postcards to Palmyra project"
#' author: "Daniel Pett"
#' date: "19/05/2016"
#' output: csv_document
#' ----
#' 

# Set working directory (for example as below)
setwd("~/Documents/research/micropasts/analysis/postcardToPalmyra/") #MacOSX
#setwd("C:\\micropasts\\analysis") #Windows
#setwd("micropasts/analysis") #Linux

# Add necessary library
library(jsonlite)
library(plyr)
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

# Set the project name
project <- 'postcardsToPalmyra'

# Load user data
#http://crowdsourced.micropasts.org/admin/users/export?format=csv (when logged in as admin)
users <- read.csv("csv/all_users.csv", header=TRUE)

# Set up user details
users <- users[,c("id","fullname")]
names(users) <- c("userID", "fullname")

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

# Rename columns
names(trT) <- c('taskID', 'rawImage', 'mediumImage', 'url', 'image', 'title')

# Import task runs from json
taskruns <- '/tasks/export?type=task_run&format=json'
urlRuns <- paste(baseUrl,project, taskruns, sep='')
print(urlRuns)
archiveRuns <-paste('archives/', project, 'TasksRun.zip', sep='')
download.file(urlRuns,archiveRuns)
unzip(archiveRuns)
taskruns <- paste('json/', project, '_task_run.json', sep='')
renameRuns <-paste(project, '_task_run.json', sep='')   

file.rename(renameRuns, taskruns)
json = fromJSON(taskruns)
transcriptionEntry <- json$info

# Re-arrange slightly and drop some columns
meta <- cbind(json$info,json$user_id,json$task_id)
names(meta)[length(names(meta))] <- "taskID"
names(meta)[length(names(meta))-1] <- "userID"
taskData <- merge( meta,trT, by="taskID")

# Final data pumped out
named <- merge(taskData, users, by="userID", all.x=TRUE)
finalData <- named[order(named$taskID),]
finalData$userID <- NULL
row.names(finalData)<-NULL

# Write CSV file output
csvname <- paste('csv/', project, '.csv', sep='')
write.csv(finalData, file=csvname,row.names=FALSE, na="")