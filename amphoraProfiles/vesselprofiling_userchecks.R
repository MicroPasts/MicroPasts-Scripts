######

# This script only downloads and processes one vessel outline at a time. You need to know the app name and task ID of the vessel you want

# The script will go through each user contribution and compile a quick summary of relevant statistics about the contribution, plus a pdf plot of what the contribution looks like.

# The script is meant to be run before running a second R-script called vesselprofiling_2Dbuild.R which builds a clean 2D shapefile and other outputs.

# Andy Bevan 03-March-2015

######

# Set-up (things you can change)
setwd("~/Documents/research/micropasts/analysis/amphs/examples") #MacOSX
appname <- "amphs1" #the app from which you wish to extract an outline.
taskID <- 31370 #which task you want to model

######

## Preliminaries ##

#Below this line, do not change anything.
# Add necessary library
library(jsonlite)
library(rgdal)
library(rgeos)
library(maptools)

# Import task runs from json
trTrURL <- paste("http://crowdsourced.micropasts.org/app/",appname,"/",taskID,"/results.json", sep="")
trTr <- fromJSON(paste(readLines(trTrURL), collapse=""))

# First, calculate some summary stats for each submitted task run. The, if a user ID has been specified, extract just this task run. If not, pick the best one based on the summary stats.
details <- c("TaskID","AppName","DrURL","Image","Drawing", "UserID", "ScaleBar", "SBLength", "Dimension","External", "Internal", "MidLine", "NeckJoin", "LHandle", "RHandle", "Section", "Comments","StepCount","NodeCount")
TrDetails <- as.data.frame(matrix(ncol=length(details), nrow=length(trTr$user_id)), )
names(TrDetails) <- details
# Populate with basic details and statistics
TrDetails$TaskID <- taskID
TrDetails$AppName <- appname
for (a in 1:length(trTr$user_id)){
    drurl <- trTr[a,]$info$img
    dr <- strsplit(drurl,"/")[[1]]
    dr <- dr[length(dr)]
    TrDetails$DrURL[a] <- drurl
    TrDetails$Image[a] <- dr
    TrDetails$Drawing[a] <- strsplit(dr,"[.]")[[1]][1]
    TrDetails$UserID[a] <- trTr$user_id[a]
    TrDetails$Comments[a] <- trTr$info$comments[a]
    TrDetails$Dimension[a] <- trTr$info$dimension[a]
    TrDetails$ScaleBar[a] <- length(trTr[a,]$info$scalebar[[1]])/2
    sb <- trTr[a,]$info$scalebar[[1]]
    sb <- data.frame(X=sb[,,1],Y=sb[,,2])
    TrDetails$SBLength[a] <- as.numeric(dist(sb))
    TrDetails$External[a] <- length(trTr[a,]$info$external[[1]])/2
    TrDetails$Internal[a] <- length(trTr[a,]$info$internal[[1]])/2
    TrDetails$MidLine[a] <- length(trTr[a,]$info$midline[[1]])/2
    TrDetails$NeckJoin[a] <- length(trTr[a,]$info$neckjoin[[1]])/2
    TrDetails$LHandle[a] <- length(trTr[a,]$info$lhandle[[1]])/2
    TrDetails$RHandle[a] <- length(trTr[a,]$info$rhandle[[1]])/2
    TrDetails$Section[a] <- length(trTr[a,]$info$section[[1]])/2
    TrDetails$StepCount[a] <- sum(!is.na(TrDetails[a,7:15]) & TrDetails[a,7:15]!=0)
    TrDetails$NodeCount[a] <- sum(TrDetails[a,9:15], na.rm=TRUE)
}

# Create a directory for this drawing if needed (will warn you but create nothing if they directory already exists)
dir.create(TrDetails$Drawing[1])
# Create a checks sub-directory
dir.create(paste(TrDetails$Drawing[1],"/userchecks",sep="")) 
# Download the original drawing
download.file(URLencode(TrDetails$DrURL[1]),paste(TrDetails$Drawing[1],"/userchecks/",dr,sep=""))
# Save the summary statistics.
write.csv(TrDetails, paste(TrDetails$Drawing[1],"/userchecks/","taskruns_details.csv",sep=""), row.names=FALSE)


######

## Line Build Steps ##

dev.new(device=pdf, height=6, width=4)

for (a in 1:nrow(TrDetails)){
    myamph <- trTr[trTr$user_id == as.character(TrDetails$UserID[a]),, drop=FALSE]
    
    # Build into external lines
    ext <- myamph$info$external[[1]]
    ext <- as.data.frame(apply(ext, 4, rbind))
    names(ext) <- c("X","Y")
    ext <- Line(ext)
    ext <- Lines(list(ext), ID=1)
    ext <- SpatialLines(list(ext))
    plot(ext, col="bisque4", axes=FALSE)

    if (length(myamph$info$internal[[1]]) > 0){
        # Build into internal line
        int <- myamph$info$internal[[1]]
        int <- as.data.frame(apply(int, 4, rbind))
        names(int) <- c("X","Y")
        int <- Line(int)
        int <- Lines(list(int), ID=2)
        int <- SpatialLines(list(int))
        plot(int, col="darkred", add=TRUE)
    }
    
    if (length(myamph$info$midline[[1]]) > 0){
        # Build mid-line line
        ml <- myamph$info$midline[[1]]
        ml <- as.data.frame(apply(ml, 4, rbind))
        names(ml) <- c("X","Y")
        ml <- Line(ml)
        ml <- Lines(list(ml), ID=3)
        ml <- SpatialLines(list(ml))
        plot(ml, col="black", add=TRUE)
    }
    if (length(myamph$info$neckjoin[[1]]) > 0){
        # Build neck-join line
        nj <- myamph$info$neckjoin[[1]]
        nj <- as.data.frame(apply(nj, 4, rbind))
        names(nj) <- c("X","Y")
        nj <- Line(nj)
        nj <- Lines(list(nj), ID=4)
        nj <- SpatialLines(list(nj))
        plot(nj, col="grey75", add=TRUE)
    }
    if (length(myamph$info$lhandle[[1]]) > 0){
        # Build left-handle line
        lh <- myamph$info$lhandle[[1]]
        lh <- as.data.frame(apply(lh, 4, rbind))
        names(lh) <- c("X","Y")
        lh <- Line(lh)
        lh <- Lines(list(lh), ID=3)
        lh <- SpatialLines(list(lh))
        plot(lh, col="brown", add=TRUE)
    }
    if (length(myamph$info$rhandle[[1]]) > 0){
        # Build right-handle line
        rh <- myamph$info$rhandle[[1]]
        rh <- as.data.frame(apply(rh, 4, rbind))
        names(rh) <- c("X","Y")
        rh <- Line(rh)
        rh <- Lines(list(rh), ID=3)
        rh <- SpatialLines(list(rh))
        plot(rh, col="brown2", add=TRUE)
    }
    if (length(myamph$info$section[[1]]) > 0){
        # Build handle section
        hs <- myamph$info$section[[1]]
        hs <- as.data.frame(apply(hs, 4, rbind))
        names(hs) <- c("X","Y")
        hs <- Line(hs)
        hs <- Lines(list(hs), ID=7)
        hs <- SpatialLines(list(hs))
        plot(hs, col="black", add=TRUE)
    }
    # Save a pdf summary
    dev.print(device=pdf, paste(TrDetails$Drawing[1],"/userchecks/",TrDetails$Drawing[1],"_user",TrDetails$UserID[a],".pdf", sep=""))
}
dev.off()
