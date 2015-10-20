#' ----
#' title: " A script for manipulation of the Worthington George Smith British Museum data"
#' author: "Daniel Pett"
#' date: "10/16/2015"
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

# Add necessary library
library(jsonlite)
library(plyr)

# Load user data
# http://crowdsourced.micropasts.org/admin/users/export?format=csv (when logged in as admin)
# This saves as all_users.csv and put this in the csv folder

users <- read.csv('../users/all_users.csv', header=TRUE)
users <- users[,c("id","fullname")]
names(users) <- c("userID", "fullname")
# Set the project name
project <- 'wgs'
# Set the base url of the application
baseUrl <- 'http://crowdsourced.micropasts.org/project/'
# Set the task runs api path
tasks <- '/tasks/export?type=task&format=json'
# Form the export url
url <- paste(baseUrl,project, tasks, sep='')
print(url)
archives <- paste('archives/',project,'Tasks.zip', sep='')
print(archives)
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
names(trT) <- c("taskID","imageURL")

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
# Get the JSON data
# One major issue is the way people did not follow instructions. Some manual data fixing needed to work
# on some data sets.
json = fromJSON(taskruns)
transcriptionEntry <- json$info$transcription

# Unlist the data
df <- lapply(transcriptionEntry, function(trans)
{
  data.frame(unlist(trans))
})
df <-do.call(rbind,df)

# Get counts for repeating the rows
counting <- lapply(transcriptionEntry, function(trans)
{
  nrow(unlist(trans))
})
counting <-do.call(rbind,counting)
# Get new data to play with
dataToPlay <- json[,c(2,3,4)]
dataToPlay$rep <- counting
#create metadata
library(mefa)
meta <- rep(dataToPlay, dataToPlay$rep)
metadata <- data.frame(meta[,c(1,2,3)])
# Append metadata that we want
df$userID <- metadata$user_id
df$taskID <- metadata$task_id
df$created <- metadata$created
#name the columns
names(df) <- c('EntryNumber', 'Date', 'Transcription', 'Length (in)', 'Width (in)', 'Weight (lbs)', 'Weight (oz)', 'userID', 'taskID', 'created')
imageUrl <- merge( df,trT, by="taskID")
# Now add the credits to the data
finaldata <- merge(imageUrl,users, by="userID")
# Arrange data for use
csv <- arrange(finaldata,EntryNumber)
# Export as csv file
csvname <- paste('csv/', project, '.csv', sep='')
write.csv(csv, file=csvname, row.names=FALSE, na="")