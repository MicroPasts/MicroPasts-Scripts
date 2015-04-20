## Creation of contributors to project text file.

# Set working directory (for example as below)
setwd("~/Documents/research/micropasts/analysis/contributions/") #MacOSX
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

# Load library
library(jsonlite)

# Import tasks from json, this method has changed due to coding changes by SciFabric to their code

download.file("http://crowdsourced.micropasts.org/app/eesAmarna/tasks/export?type=task_run&format=json",'archives/eesAmarnaTasksRun.zip')
unzip("archives/eesAmarnaTasksRun.zip")
taskruns <- 'json/eesAmarna_task_run.json'
file.rename("eesAmarna_task_run.json", taskruns)

# Get the user id from the task run data
data <- fromJSON(paste(readLines(taskruns), collapse=""))
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

as.vector(contributors$fullname) -> names

#Extract and print unique names
unique(names) -> names
thanks <- paste(as.character(names), collapse=", ")

# Write the thank you list to a text file.
fileConn<-file("thanksEESArmarna.txt")
writeLines(c(thanks), fileConn)
close(fileConn)