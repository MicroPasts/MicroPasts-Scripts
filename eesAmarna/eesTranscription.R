# This builds on Andy Bevan's previous script for the BAI

# Set working directory (for example as below)
setwd("~/Documents/research/micropasts/analysis/eesArmana/") #MacOSX
#setwd("C:\\micropasts\\analysis") #Windows
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

# Load user data
# http://crowdsourced.micropasts.org/admin/users/export?format=csv (when logged in as admin)
# This saves as all_users.csv and put this in the csv folder

users <- read.csv('csv/all_users.csv', header=TRUE)
users <- users[,c("id","fullname","name")]

# Import tasks from json, this method has changed due to coding changes by SciFabric to their code
download.file("http://crowdsourced.micropasts.org/app/eesAmarna/tasks/export?type=task&format=json",'archives/eesArmanaTasks.zip')
unzip('archives/eesArmanaTasks.zip')
task <- 'json/eesAmarna_task.json'
file.rename("eesAmarna_task.json", task)

# Read json files
which(lapply(readLines(task), function(x) tryCatch({jsonlite::fromJSON(x); 1}, error=function(e) 0)) == 0)
trT <- fromJSON(paste(readLines(task), collapse=""))
trT <- cbind(trT$id,trT$info)
trTfull <- trT

# extract just task id and image URL, title
trT <- trT[,c(1,4,6)]
names(trT) <- c("taskID","imageURL", "imageTitle")

# Import task runs from json
download.file("http://crowdsourced.micropasts.org/app/eesAmarna/tasks/export?type=task_run&format=json",'archives/eesAmarnaTasksRun.zip')
unzip("archives/eesAmarnaTasksRun.zip")
taskruns <- 'json/eesAmarna_task_run.json'
file.rename("eesAmarna_task_run.json", taskruns)
which(lapply(readLines(taskruns), function(x) tryCatch({jsonlite::fromJSON(x); 1}, error=function(e) 0)) == 0)
trTr <- fromJSON(paste(readLines(taskruns), collapse=""))

# Re-arrange slightly and drop some columns
trTr <- cbind(trTr$info,trTr$user_id,trTr$task_id)
names(trTr)[length(names(trTr))] <- "taskID"
names(trTr)[length(names(trTr))-1] <- "userID"

# Sort by user ID then by task ID
trTr <- trTr[with(trTr, order(taskID, userID)), ]

# Add user credit
tsks <- unique(as.character(trTr$taskID))
credits <- data.frame(taskID=character(length(tsks)),inputBy=character(length(tsks)), stringsAsFactors = FALSE) #blank df to fill

for (a in 1:length(tsks)){
  atask <- trTr[trTr$taskID == tsks[a],]
  contribs <- sort(unique(as.numeric(as.character(atask$userID))))
  contribsNm <- users[users$id %in% contribs,]
  credits$taskID[a] <- tsks[a]
  credits$inputBy[a] <- paste(as.character(contribsNm$fullname), collapse="; ")
}

# Merge task summaries with image URL and user credit data.
credurl <- merge(credits, trT, by="taskID")
trTr <- merge(trTr,credurl, by="taskID")

# Add two skipped lines between each unique index cards (i.e. between task sets).
trTr1 <- trTr[which(is.na(trTr$taskID)), ] #blank df to fill
newrow <- rep(NA,ncol(trTr))

for (a in 1:length(tsks)){
  atask <- trTr[trTr$taskID == tsks[a],]
  trTr1 <- rbind(trTr1,atask,newrow,newrow)
}

# Annotations column not really needed, so dropped
keeps <- c("taskID","userID","provenance", "title", "imageTitle", "objectNumber", 'negativeNumber', 'distribution', 'otherNotes', 'inputBy', 'comments', 'imageURL')
trTr2 <- trTr1[,keeps,drop=FALSE]

# Finally reorder the columns fo the data to something easier to refer to:
preforder <- c("taskID","userID","provenance", "title", "imageTitle", "objectNumber", "negativeNumber", "distribution", "otherNotes", "comments", "imageURL", "inputBy")
trTr2 <- trTr2[ ,preforder]

# Export as csv file
write.csv(trTr2, file="csv/eesAmarna.csv",row.names=FALSE, na="")