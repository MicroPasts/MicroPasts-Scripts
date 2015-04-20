## Creation of contributors to project text file.

# Set working directory (for example as below)
setwd("~/Documents/research/micropasts/analysis/countsAndGraphs/") #MacOSX
#setwd("C:\\micropasts\\analysis") #Windows
#setwd("micropasts/analysis") #Linux

# Create CSV directory if it does not exist
if (!file.exists('csv')){
  dir.create('csv')
}

# Create archives directory if it does not exist
if (!file.exists('archives')){
  dir.create('archives')
}

# Create JSON folder if it does not exist
if (!file.exists('json')){
  dir.create('json')
}

# Create JSON folder if it does not exist
if (!file.exists('data')){
  dir.create('data')
}
# Load library
library(jsonlite)
library(plyr)

# Set the project name
project <- 'eesAmarna'

# Set the base url of the application
baseUrl <- 'http://crowdsourced.micropasts.org/app/'

# Set the task runs api path
taskruns <- '/tasks/export?type=task_run&format=json'

# Form the export url
url <- paste(baseUrl,project,taskruns, sep='')

# Create the archive path
archive <- paste('archives/', project, 'TasksRun.zip', sep='')

# Create the task run file name
taskruns <- paste(project, '_task_run.json', sep= '' )

# Create the task run file path
taskrunsPath <- paste('json/', project, '_task_run.json', sep= '' )

# Import tasks from json, this method has changed due to coding changes by SciFabric to their code
download.file(url, archive)

# Unzip the archive
unzip(archive)

# Rename the archive
file.rename(taskruns, taskrunsPath)

# Get the user id from the task run data
data <- fromJSON(paste(readLines(taskrunsPath), collapse=""))
data <- as.data.frame(data)
user_id <- data$user_id
as.data.frame(user_id) -> user_id

# Load user data
# http://crowdsourced.micropasts.org/admin/users/export?format=csv (when logged in as admin)
# This saves as all_users.csv and put this in the csv folder
users <- read.csv('csv/all_users.csv', sep=",", header=TRUE)
userList <- users[,c("id","fullname")]

# Rename column id to user_id for merging 
names(userList) <- c("user_id", "fullname")

# Merge the data
contributors <- merge(user_id, userList, by="user_id")
freq <- count(contributors, "fullname")
names(freq) <- c("contributor", "tasks")
orderedData <- arrange(freq,tasks)
write.csv(orderedData, file="data/eesAmarnaCounts.csv",row.names=FALSE, na="")
