
# Set working directory (for example as below)
setwd("~/Documents/research/micropasts/analysis/denverMuseums/") #MacOSX
#setwd("C:\\micropasts\\analysis") #Windows
#setwd("micropasts/analysis") #Linux

# Add necessary library
library(jsonlite)

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

# Load user data
users <- read.csv("csv/all_users.csv", header=TRUE)
users <- users[,c("id","name", "fullname")]
names(users) <- c("userID", "name", "fullname")
users <- users[order(users$userID),]

# Set the project name
project <- 'DenverAnthro'

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

# extract just task id and image URL
trT <- trT[,c(1,4)]
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
which(lapply(readLines(taskruns), function(x) tryCatch({jsonlite::fromJSON(x); 1}, error=function(e) 0)) == 0)
trTr <- fromJSON(paste(readLines(taskruns), collapse=""))

# Re-arrange slightly and drop some columns
trTr <- cbind(trTr$info,trTr$user_id,trTr$task_id)
names(trTr)[length(names(trTr))] <- "taskID"
names(trTr)[length(names(trTr))-1] <- "userID"

# Sort by user ID then by task ID
trTr <- trTr[with(trTr, order(taskID, userID)), ]

# Use regular expressions to clean up some issues to do with line breaks and our special transcription symbol [;]
tmp <- names(trTr) #preserve column names
trTr <- apply(trTr, 2, function(x) gsub("[\r\n]", " [;] ", x))
trTr <- apply(trTr, 2, function(x) gsub("[;]", " [;] ", x, fixed=TRUE))
# Now there are extra whitespaces around this character, so clean them up to have just one.
trTr <- apply(trTr, 2, function(x) gsub("\\s+", " ", x))
# Now get rid of multiple instances (there must be a better way to do this using {2,}, but the '[' character makes it tricky, so brute force for now...
trTr <- apply(trTr, 2, function(x) gsub(" [;] [;] [;] [;] [;] ", " [;] ", x, fixed=TRUE)) #five times
trTr <- apply(trTr, 2, function(x) gsub(" [;] [;] [;] [;] ", " [;] ", x, fixed=TRUE)) #four times
trTr <- apply(trTr, 2, function(x) gsub(" [;] [;] [;] ", " [;] ", x, fixed=TRUE)) #three times
trTr <- apply(trTr, 2, function(x) gsub(" [;] [;] ", " [;] ", x, fixed=TRUE)) #twice
trTr <- data.frame(trTr)
names(trTr) <- tmp
head(trTr)
named <- merge(users, trTr, by="userID")
finalData <- named[order(named$taskID),]
tsks <- unique(as.character(trTr$taskID))

# Add one line between each unique index cards (i.e. between task sets).
trTr1 <- trTr[which(is.na(trTr$taskID)), ] #blank df to fill
newrow <- rep(NA,ncol(trTr))
for (a in 1:length(tsks)){
  atask <- trTr[trTr$taskID == tsks[a],]
  trTr1 <- rbind(trTr1,atask,newrow)
}
# Export as csv file
csvname <- paste('csv/', project, '.csv', sep='')
write.csv(trTr1, file=csvname,row.names=FALSE, na="")