# Set working directory (for example as below)
setwd("~/Documents/MicroPasts/Crowd-Sourcing/Rice_and_Population/Data") #MacOSX
#setwd("C:\\micropasts\\analysis") #Windows
#setwd("micropasts/analysis") #Linux

# Add necessary library
library(jsonlite)

# Load user data
# http://crowdsourced.micropasts.org/admin/users/export?format=csv (when logged in as admin)
users <- read.csv("csv/all_users.csv", header=TRUE)
users <- users[,c("id","fullname","name")]

# Import tasks from json: download and unzip
download.file("http://crowdsourced.micropasts.org/app/ricepops2/tasks/export?type=task&format=json",'ricepops2Tasks.zip')
unzip('ricepops2Tasks.zip')
task <- 'ricepops2_task.json'

trT <- fromJSON(paste(readLines(task), collapse=""))
trT <- cbind(trT$id,trT$info)

# extract just task id and image URL
trT <- trT[,c(1,2)]
names(trT) <- c("taskID","imageURL")

# Import task runs from json: download and unzip
download.file("http://crowdsourced.micropasts.org/app/ricepops2/tasks/export?type=task_run&format=json",'ricepops2TaskRuns.zip')
unzip('ricepops2TaskRuns.zip')
taskruns <- 'ricepops2_task_run.json'

trTr <- fromJSON(paste(readLines(taskruns), collapse=""))

# Loop through and write out tables
for (a in 1:length(trTr$info)){
     trdata <- as.data.frame(trTr$info[[a]])
     write.table(trdata, file=paste("csv/ricepops2/","task-",trTr$task_id[a],"_user-",trTr$user_id[a],".csv", sep=""),row.names=FALSE, col.names=FALSE, sep=",")
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
write.csv(credits, file="csv/ricepops2/ricepops2_info.csv",row.names=FALSE)
