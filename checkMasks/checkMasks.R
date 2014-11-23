
# Set working directory (for example as below)
setwd("~/Documents/research/micropasts/analysis") #MacOSX
#setwd("C:\\micropasts\\analysis") #Windows
#setwd("micropasts/analysis") #Linux

# Add necessary library
library(jsonlite)

# Import tasks from json
trTURL <- "http://crowdsourced.micropasts.org/app/photomaskingArreton/tasks/export?type=task&format=json"
#trTURL <- "http://crowdsourced.micropasts.org/app/photomasking/tasks/export?type=task&format=json"
trT <- fromJSON(paste(readLines(trTURL), collapse=""))
trT <- cbind(trT$id,trT$info)
names(trT) <- c("id","url")

# Extract museum accession nos for objects from parent folder of image
urls <- trT$url
urls <- strsplit(urls,"/")
objects <- vector("character", length=length(urls))
for (a in 1:length(urls)){
    objects[a] <- urls[[a]][length(urls[[a]])-1]
}
objtasks <- data.frame(objects=objects,task_id=trT$id)

# Import photomasking task runs from json
pmTrUrl <- "http://crowdsourced.micropasts.org/app/photomaskingArreton/tasks/export?type=task_run&format=json"
#pmTrUrl <- "http://crowdsourced.micropasts.org/app/photomasking/tasks/export?type=task_run&format=json"
pmTr <- fromJSON(paste(readLines(pmTrUrl), collapse=""))
pmTr1 <- pmTr[,names(pmTr) != "info"]

# Count up total runs per task
totals <- as.data.frame(t(table(pmTr1$task_id)))[,2:3]
names(totals) <- c("task_id","Count")

# Merge
objtasks1 <- merge(objtasks, totals, by="task_id", all.x=TRUE)

# Set minimum number of require masks
minmasks <- 2

# Get tasks with mininum required number of masks for all photos.
myobjects <- unique(as.character(objtasks1$objects))
readyobjects <- vector()
for (b in 1:length(myobjects)){
    myobjtasks <- objtasks1[objtasks1$objects == myobjects[b],]
    test <- all(myobjtasks$Count >= minmasks)
    if (is.na(test)){ test <- FALSE }
    if (test){
        readyobjects[b] <- myobjects[b]
    }
}

#So the objects ready to be modelled are these:
readyobjects

