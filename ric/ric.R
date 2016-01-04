#' ----
#' title: " A script for manipulation of the PAS data for RIC identifiers"
#' author: "Daniel Pett"
#' date: "02/01/2016"
#' output: csv_document | RDF
#' ----
#' 

# Set working directory (for example as below)
setwd("~/Documents/research/micropasts/analysis/ric/") #MacOSX
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
project <- 'ricConcordance'

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
objects <- as.data.frame(trT$object)
names(objects) <- c('uri')
obj <- cbind(read.table(text = names(objects)), objects)
trT <- trT[,order(names(trT))]
names(trT) <- c('match1', 'match2', 'match3', 'match4', 'object', 'taskID')
# Download PAS data using lapply
get.data <- function(objects){
  uri <- paste(objects, '/format/json', sep = '')
  stable <- objects
  json <- fromJSON(uri)
  keeps <- c("id","old_findID","numdate1", "numdate2", "denomination", "mintName",
             "primaryRuler", "ricID", "obverseDescription",  "obverseInscription",
             "reverseDescription", "reverseInscription", "object")
  raw <- as.data.frame(json[2])
  raw$object <- objects
  raw <- raw[,(names(raw) %in% keeps)]
}
frame2 <- lapply(objects[1:262,], get.data)

# Convert the list of data frames to a data frame
df <- ldply(frame2, data.frame)

# Save a csv file of the coin data for fun and giggles.
csvname <- paste('csv/', 'coinData.csv', sep='')
write.csv(df, file=csvname,row.names=FALSE, na="")

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
withCoinData <- merge(taskData, df, by="object")
# Final data pumped out
named <- merge(withCoinData, users, by="userID", all.x=TRUE)
finalData <- named[order(named$taskID),]
finalData$userID <- NULL
finalData$unattributable[finalData$unattributable =="0"] <- ""
finalData$unattributable[finalData$unattributable =="1"] <- "No match can be made" 
finalData$revisePas[finalData$revisePas =="0"] <- "" 
finalData$revisePas[finalData$revisePas =="1"] <- "The PAS record needs revising" 
csvname <- paste('csv/', project, '.csv', sep='')
write.csv(finalData, file=csvname,row.names=FALSE, na="")