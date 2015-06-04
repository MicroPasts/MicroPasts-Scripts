
## Set-up (global variables) ##

# Set working directory (for example as below)
setwd("~/Desktop/tmp") #MacOSX
#setwd("C:\\micropasts\\analysis") #Windows
#setwd("micropasts/analysis") #Linux

# Add necessary library
library(jsonlite)

# Set the table transcription application you want to get data from
app <- 'japanrice'

# Make sure to also have downloaded the following user data into the working directory. You need to already be logged into MicroPasts site as an admin user to access it (also make sure to download a fresh up-to-date user csv before you run the script or you will most likely get an error below).
# http://crowdsourced.micropasts.org/admin/users/export?format=csv

##################################################################

## Rest of script (no changes needed) ##

# Get user data from csv
users <- read.csv("all_users.csv", header=TRUE)
users <- users[,c("id","fullname","name")]

# Import tasks from json: download and unzip
download.file(paste("http://crowdsourced.micropasts.org/app/",app,"/tasks/export?type=task&format=json", sep=""),'tmp.zip')
unzip('tmp.zip')
task <- paste(app,"_task.json",sep="")
trT <- fromJSON(paste(readLines(task), collapse=""))
trT <- cbind(trT$id,trT$info)
# Extract just task id and image URL
trT <- trT[,c(1,2)]
names(trT) <- c("taskID","imageURL")

# Import task runs from json: download and unzip
download.file(paste("http://crowdsourced.micropasts.org/app/",app,"/tasks/export?type=task_run&format=json",sep=""),'tmp.zip')
unzip('tmp.zip')
taskruns <- paste(app,"_task_run.json",sep="")
trTr <- fromJSON(paste(readLines(taskruns), collapse=""))
file.remove("tmp.zip",paste(app,"_task.json",sep=""),paste(app,"_task_run.json",sep=""))

# Loop through and write out tables
for (a in 1:length(trTr$info)){
     trdata <- as.data.frame(trTr$info[[a]])
     write.table(trdata, file=paste(app,"_task-",trTr$task_id[a],"_user-",trTr$user_id[a],".csv", sep=""),row.names=FALSE, col.names=FALSE, sep=",", fileEncoding="UTF-8")
}

# Add user credit
tsks <- unique(as.character(trTr$task_id))
credits <- data.frame(taskID=character(length(tsks)),inputBy=character(length(tsks)), stringsAsFactors = FALSE) #blank df to fill
for (a in 1:length(tsks)){
    atask <- trTr[trTr$task_id == tsks[a],]
    contribs <- sort(unique(as.numeric(as.character(atask$user_id))))
    contribsNm <- users[users$id %in% contribs,]
    credits$taskID[a] <- tsks[a]
    credits$inputBy[a] <- paste(as.character(contribsNm$fullname), collapse="; ")
}
credits <- merge(trT,credits,by="taskID")
write.csv(credits, file=paste(app,"_info.csv",sep=""),row.names=FALSE)
