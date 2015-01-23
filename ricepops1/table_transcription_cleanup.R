
# Set working directory (for example as below)
setwd("~/Documents/research/micropasts/analysis") #MacOSX
#setwd("C:\\micropasts\\analysis") #Windows
#setwd("micropasts/analysis") #Linux

# Add necessary library
library(jsonlite)

# Load user data
#http://crowdsourced.micropasts.org/admin/users/export?format=csv (when logged in as admin)
users <- read.csv("csv/users.csv", header=TRUE)
users <- users[,c("id","fullname","name")]

# Import tasks from json
trTURL <- "http://crowdsourced.micropasts.org/app/ricepops1/tasks/export?type=task&format=json"
trT <- fromJSON(paste(readLines(trTURL), collapse=""))
trT <- cbind(trT$id,trT$info)
# extract just task id and image URL
trT <- trT[,c(1,2)]
names(trT) <- c("taskID","imageURL")

# Import task runs from json
trTrURL <- "http://crowdsourced.micropasts.org/app/ricepops1/tasks/export?type=task_run&format=json"
trTr <- fromJSON(paste(readLines(trTrURL), collapse=""))

# Loop through and write out tables
for (a in 1:length(trTr$info)){
     trdata <- as.data.frame(trTr$info[[a]])
     write.table(trdata, file=paste("csv/ricepops1/","task-",trTr$task_id[a],"_user-",trTr$user_id[1],".csv", sep=""),row.names=FALSE, col.names=FALSE, sep=",")
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
write.csv(credits, file="csv/ricepops1/ricepops1_info.csv",row.names=FALSE)
