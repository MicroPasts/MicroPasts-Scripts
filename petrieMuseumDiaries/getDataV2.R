#' ----
#' title: " A script for manipulation of the diaries of Flinders Petrie"
#' author: "Daniel Pett"
#' date: "10/16/2015"
#' output: csv_document
#' ----

# Set working directory (for example as below)
setwd("~/Documents/research/micropasts/analysis/petrie/") #MacOSX
#setwd("C:\\micropasts\\analysis\\petrie") #Windows
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
library(mefa)

# Load user data
# http://crowdsourced.micropasts.org/admin/users/export?format=csv (when logged in as admin)
# This saves as all_users.csv and put this in the csv folder

users <- read.csv('../users/all_users.csv', header=TRUE)
users <- users[,c("id","fullname")]
names(users) <- c("userID", "fullname")

# Set the project name
project <- 'PetrieDiaries1894'
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
trT <- trT[,c(1,4,6)]
names(trT) <- c("taskID","imageURL", "imageTitle")

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
imageUrl <- merge( meta,trT, by="taskID")
named <- merge(imageUrl, users, by="userID", all.x=TRUE)
# Finally reorder the columns fo the data to something easier to refer to:
preforder <- c(
  "taskID","userID","day1date", "day1text", "day2date", "day2text", "day3date", "day3text", 
  "day4date", "day4text", "comments", "imageURL", "imageTitle", "fullname")
final <- named[ ,preforder]
csv <- arrange(final,taskID)
# Export as csv file
csvname <- paste('csv/', project, '.csv', sep='')
write.csv(csv, file=csvname, row.names=FALSE, na="")
