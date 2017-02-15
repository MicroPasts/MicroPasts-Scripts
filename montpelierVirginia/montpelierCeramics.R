#' ----
#' title: " A script for manipulation of the Montpelier Ceramics crowdsourcing project
#' author: "Daniel Pett"
#' date: "15/02/2017"
#' output: csv_document
#' ----
# Set the project name
project <- 'montpelierCeramics'

# Set working directory (for example as below)
pathToDir <- paste0("~/Dropbox/Terry (1)/Archaeology/micropasts/analysis/",project)

if (!file.exists(pathToDir)){
  dir.create(pathToDir)
}

setwd(pathToDir) #MacOSX

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
# Set up packages for mapping
list.of.packages <- c(
  'jsonlite', 'stringr'
)

# Install packages if not already available
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
# Add necessary libraries
library(jsonlite)
library(stringr)

# Load user data
# http://crowdsourced.micropasts.org/admin/users/export?format=csv (when logged in as admin)
# This saves as all_users.csv and put this in the csv folder

users <- read.csv('csv/all_users.csv', header=TRUE)
users <- users[,c("id","fullname","name")]



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

# Read the transcription data
transcriptionEntry <- json$info
resultsCount <- nrow(json)
data <- NULL
# Ignore first 3 entries as they were junk 
for (a in resultsCount){
  test <- as.data.frame(json$info$table[a])
  test$DEcode <- json$info$deCode[a]
  test$pageNumber <- json$info$pageNumber[a]
  test$siteNumber <- json$info$siteNumber[a]
  test$taskID <- json$task_id[a]
  test$userID <- json$user_id[a]
  #remove the rubbish empty rows
  test <- test[(1:24),]
  data <- rbind(data, test) 
}
# Enforced to UPPER
data <- as.data.frame(sapply(data, toupper))
#data <- subset(data, !is.na(DEcode) & !is.na(X1))
#data <- data[order(data[16],data[14],data[1]),]
colnames(data) <- c(
  'Inv #', 'Catalog Letter', 'NCatnum', 'Material',
  'Function', 'Color', 'Condition', 'Artifact Type', 'Number', 'Grams', 'Artifact Size',
  'Notes', 'Problem','DE code', 'Page number', 'Site number', 'taskID', 'userID'
  )

# Set up user details
names(users) <- c("userID", "fullname")
named <- merge(data, users, by="userID", all.x=FALSE)

# Merge for file paths to be added by line
named <- merge(named, trT, by="taskID", all.x=FALSE)

# Tentative ordering
named <- named[order(named['taskID'], named['Inv #']),]

# Write CSV file output
csvname <- paste('csv/', project, '.csv', sep='')
write.csv(named, file=csvname,row.names=FALSE, na="")
