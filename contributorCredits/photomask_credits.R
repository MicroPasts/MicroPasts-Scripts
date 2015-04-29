
# Set working directory (for example as below)
setwd("~/Documents/MicroPasts/Crowd-Sourcing/3D_Modelling/Models") #MacOSX
#setwd("C:\\micropasts\\analysis") #Windows
#setwd("micropasts/analysis") #Linux

# Add necessary library
library(jsonlite)

# Object we are looking for (this should be exactly as written for S3 bucket):
obj <- '1927 1-7 1h'

# Load user data (download a fresh copy from link below before proceeding)
# http://crowdsourced.micropasts.org/admin/users/export?format=csv (when logged in as admin)
users <- read.csv("csv/all_users.csv", header=TRUE)
users <- users[,c("id","fullname","name")]

# Import task runs from json: download and unzip (this may take some time)
# Change app and file names in the link and variables below
download.file("http://crowdsourced.micropasts.org/app/photomaskingBurley/tasks/export?type=task_run&format=json",'photomaskingBurleyTaskRuns.zip')
unzip('photomaskingBurleyTaskRuns.zip')
myJsonDownload <- 'photomaskingBurley_task_run.json'
pmTr <- fromJSON(paste(readLines(myJsonDownload), collapse=""))

# Re-arrange slightly and drop some columns
pmTr <- cbind(pmTr$info, pmTr$user_id,pmTr$task_id)
names(pmTr)[length(names(pmTr))] <- "taskID"
names(pmTr)[length(names(pmTr))-1] <- "userID"
pmTr$outline <- NULL
pmTr$holes <- NULL

# Extract records relevant to obj above:
objruns <- pmTr[grep(obj,pmTr$img),]
    
# Merge with user data
objruns <- merge(objruns,users, by.x="userID", by.y="id")

# Extract a surname to sort on where possible.
objruns$SortName <- NA
for (a in 1:nrow(objruns)){
    fnm <- as.character(objruns$fullname[a])
    ss <- strsplit(fnm," ")[[1]]
    objruns$SortName[a] <- tail(ss, n=1)
}

# Sort contributors, extract unique names and capitalise
objruns <- objruns[order(objruns$SortName),]
contribs <- unique(as.character(objruns$fullname))

simpleCap <- function(x) {
    res <- vector(length=length(x))
    for (b in 1:length(x)){
        s <- strsplit(x[b], " ")[[1]]
        res[b] <- paste(toupper(substring(s, 1,1)), substring(s, 2), sep="", collapse=" ")
    }
    return(res)
}
contribs1 <- simpleCap(contribs)

# Copy and paste the following into the 3D model metadata .md file
cat(paste(contribs1, collapse="; "))

