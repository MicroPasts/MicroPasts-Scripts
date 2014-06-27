
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
trTURL <- "http://crowdsourced.micropasts.org/app/arretonHoard/tasks/export?type=task&format=json"
trT <- fromJSON(paste(readLines(trTURL), collapse=""))
trT <- cbind(trT$id,trT$info)
trTfull <- trT
# extract just task id and image URL
trT <- trT[,c(1,4)]
names(trT) <- c("taskID","imageURL")

# Import task runs from json
trTrURL <- "http://crowdsourced.micropasts.org/app/arretonHoard/tasks/export?type=task_run&format=json"
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

# Finally reorder the columns fo the data to something easier to refer to:
preforder <- c("taskID","userID","objectType","rightCorner","collection","site","toSearch","Lon","Lat","optionsAccuracy","gridRef","dateDiscoveryDay","dateDiscoveryMonth","dateDiscoveryYear","length","width","edge","weight","patina","surface","thickness","other","composition","associations","description","publications","remarks","inputBy","imageURL")
trTr1 <- trTr1[ ,preforder]


# Export as csv file
write.csv(trTr1, file="trTr.csv",row.names=FALSE, na="")
