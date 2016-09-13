#' ----
#' title: " A script for manipulation of the diaries of Flinders Petrie"
#' author: "Daniel Pett"
#' date: "21/08/2016"
#' output: csv_document
#' description: "A script for taking the diary entries and flattening them for use with 
#' Electric Archaeologist's bot."
#' ----

# Set working directory (for example as below)
setwd("~/Documents/research/micropasts/analysis/petrie/") #MacOSX
#setwd("C:\\micropasts\\analysis\\petrie") #Windows
#setwd("micropasts/analysis") #Linux

# Load required library
library(stringr)

df <- read.csv("/Users/danielpett/githubProjects/projectData/petrieDiairies/rawCSV/PetrieDiaries1884.csv", header=TRUE)
df <- subset(df, select = -c(imageTitle, imageURL, fullname, comments, userID, taskID) )
day1 <- subset(df, select = c(day1text,day1date))
day1 <- day1[order(day1$day1date),]
day1 <- day1[duplicated(day1$day1date), ]


day1 <- day1[!duplicated(day1$day1date), ]
day1$day1text <- str_replace_all(day1$day1text, "[\r\n]" , "")
rownames(day1) <- NULL
csvname <- paste('csv/1884', 'day1', '.csv', sep='')
print(csvname)
write.csv(day1, file=csvname, row.names=FALSE, na="")

day2 <- subset(df, select = c(day2text,day2date))
day2 <- day2[order(day2$day2date),]
day2 <- day2[duplicated(day2$day2date), ]
day2 <- day2[!duplicated(day2$day2date), ]
day2$day2text <- str_replace_all(day2$day2text, "[\r\n]" , "")
rownames(day2) <- NULL
csvname <- paste('csv/1884', 'day2', '.csv', sep='')
write.csv(day2, file=csvname, row.names=FALSE, na="")

day3 <- subset(df, select = c(day3text,day3date))
day3 <- day3[order(day3$day3date),]
day3 <- day3[duplicated(day3$day3date), ]
day3 <- day3[!duplicated(day3$day3date), ]
day3$day3text <- str_replace_all(day3$day3text, "[\r\n]" , "")
rownames(day3) <- NULL
csvname <- paste('csv/1884', 'day3', '.csv', sep='')
write.csv(day3, file=csvname, row.names=FALSE, na="")

day4 <- subset(df, select = c(day4text,day4date))
day4 <- day4[order(day4$day4date),]
day4 <- day4[duplicated(day4$day4date), ]
day4 <- day4[!duplicated(day4$day4date), ]
day4$day4text <- str_replace_all(day4$day4text, "[\r\n]" , "")
rownames(day4) <- NULL
csvname <- paste('csv/1884', 'day4', '.csv', sep='')
write.csv(day4, file=csvname, row.names=FALSE, na="")