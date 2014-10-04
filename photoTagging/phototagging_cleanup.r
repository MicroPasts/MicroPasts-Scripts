
# Set working directory (for example as below)
setwd("~/Documents/MicroPasts/Crowd-Sourcing/IoA_Photo_Collections/Horsfield") #MacOSX
#setwd("C:\\MicroPasts\\Horsfield") #Windows
#setwd("MicroPasts/Horsfield") #Linux

# Add necessary library
library(jsonlite)

# Load user data
# http://crowdsourced.micropasts.org/admin/users/export?format=csv (when logged in as admin)
users <- read.csv("users.csv", header=TRUE)
users <- users[,c("id","fullname","name")]

# Import tasks from json
trTURL <- "http://crowdsourced.micropasts.org/app/phototaggingHorsfield/tasks/export?type=task&format=json"
trT <- fromJSON(paste(readLines(trTURL), collapse=""))
trT <- cbind(trT$id,trT$info)
trTfull <- trT

# extract just task id and image URL
trT <- trT[,c(1,3)]
names(trT) <- c("taskID","imageURL")

# Import task runs from json
trTrURL <- "http://crowdsourced.micropasts.org/app/phototaggingHorsfield/tasks/export?type=task_run&format=json"
trTr <- fromJSON(paste(readLines(trTrURL), collapse=""))

# Re-arrange slightly and drop some columns
trTr <- cbind(trTr$info,trTr$user_id,trTr$task_id)
names(trTr)[length(names(trTr))] <- "taskID"
names(trTr)[length(names(trTr))-1] <- "userID"

# Extract geojson data and append lon-lat columns
geo <- trTr$geojson[,1][,2]
geo <- data.frame(do.call("rbind",geo))
names(geo) <- c("Lon","Lat")
trTr$geojson <- NULL
trTr <- cbind(trTr,geo)

# Sort by user ID then by task ID
trTr <- trTr[with(trTr, order(taskID, userID)), ]

# Sort out keyword lists in columns for theme, activities, things and people
# Theme:
thmdf <- data.frame(Theme=character(length(trTr$theme)))
thmdf$Theme <- "tmp"
thmdf$Theme <- as.character(thmdf$Theme)
theme <- trTr$theme
for (i in 1:length(theme)) {
  thmdf$Theme[i] <- paste(theme[[i]], collapse="; ")
}
trTr <- cbind(trTr,thmdf)
trTr$theme <- NULL

# Activities:
actdf <- data.frame(Activities=character(length(trTr$activities)))
actdf$Activities <- "tmp"
actdf$Activities <- as.character(actdf$Activities)
activities <- trTr$activities
for (i in 1:length(activities)) {
  actdf$Activities[i] <- paste(activities[[i]], collapse="; ")
}
trTr <- cbind(trTr,actdf)
trTr$activities <- NULL

# Things:
tngdf <- data.frame(Things=character(length(trTr$things)))
tngdf$Things <- "tmp"
tngdf$Things <- as.character(tngdf$Things)
things <- trTr$things
for (i in 1:length(things)) {
  tngdf$Things[i] <- paste(things[[i]], collapse="; ")
}
trTr <- cbind(trTr,tngdf)
trTr$things <- NULL

# People:
ppldf <- data.frame(People=character(length(trTr$people)))
ppldf$People <- "tmp"
ppldf$People <- as.character(ppldf$People)
people <- trTr$people
for (i in 1:length(people)) {
  ppldf$People[i] <- paste(people[[i]], collapse="; ")
}
trTr <- cbind(trTr,ppldf)
trTr$people <- NULL

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

# Add three skipped lines between each unique index cards (i.e. between task sets).
trTr1 <- trTr[which(is.na(trTr$taskID)), ] #blank df to fill
newrow <- rep(NA,ncol(trTr))
for (a in 1:length(tsks)){
    atask <- trTr[trTr$taskID == tsks[a],]
    trTr1 <- rbind(trTr1,atask,newrow,newrow,newrow)
}

# Finally reorder the columns of the data to something easier to refer to:
preforder <- c("taskID","imageID","imageLabel","orientation","Lon","Lat","pleiadesID","toSearch","Theme","Activities","Things","People","keywordsUser","comments","userID","inputBy","imageURL")
trTr1 <- trTr1[ ,preforder]

# Export as csv file.
write.csv(trTr1, file="output.csv",row.names=FALSE, na="")
