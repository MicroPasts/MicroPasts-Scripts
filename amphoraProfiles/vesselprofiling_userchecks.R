######

# This script only downloads and processes one vessel outline at a time. You need to know the app name and task ID of the vessel you want

# The script will go through each user contribution and compile a quick summary of relevant statistics about the contribution, plus a pdf plot of what the contribution looks like.

# The script is meant to be run before running a second R-script called vesselprofiling_2Dbuild.R which builds a clean 2D shapefile and other outputs.

# Andy Bevan

######

# Set-up (things you can change)
setwd("~/Desktop") #MacOSX
appname <- "amphs1" #the app from which you wish to extract an outline.
taskID <- 31382 #which task you want to model
whoami <- "Andrew Bevan" #will be used to credit you for processing in metadata

# The following user name file is generally not disclosed outside the porject, but we use it to give credit to named registered users. Only necessary to write the acknowledgements in the metadata. It canbe downloaded if you are logged into MicroPasts as an administrator, as follows:
#http://crowdsourced.micropasts.org/admin/users/export?format=csv
userfile <- "~/Desktop/all_users.csv"

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
dr <- TrDetails$Drawing[1]
if (!dir.exists(dr)){ dir.create(dr) }
if (!dir.exists(paste(dr,"/userchecks",sep=""))){ dir.create(paste(dr,"/userchecks",sep="")) }

# Download the original drawing
download.file(URLencode(TrDetails$DrURL[1]),paste(TrDetails$Drawing[1],"/userchecks/",dr,".jpg",sep=""))
# Save the summary statistics.
write.csv(TrDetails, paste(TrDetails$Drawing[1],"/userchecks/","taskruns_details.csv",sep=""), row.names=FALSE)


######

## Line Build Steps ##

dev.new(device=pdf, height=6, width=4)

for (a in 1:nrow(TrDetails)){
    myamph <- trTr[trTr$user_id == as.character(TrDetails$UserID[a]),, drop=FALSE]
    
    if (length(myamph$info$external[[1]]) > 1){
        # Build exto external line
        ext <- myamph$info$external[[1]]
        if (length(ext) <= 4){
            myi <- which.max(unlist(lapply(myamph$info$external[[1]], function(x) length(x))))
            ext <- myamph$info$external[[1]][[myi]]
            ext <- as.data.frame(cbind(ext[,,1],ext[,,2]))
        } else {
            ext <- as.data.frame(apply(ext, 4, rbind))
        }
        names(ext) <- c("X","Y")
        ext <- Line(ext)
        ext <- Lines(list(ext), ID=2)
        ext <- SpatialLines(list(ext))
        plot(ext, col="bisque4", axes=FALSE)
    }

    if (length(myamph$info$internal[[1]]) > 1){
        # Build into internal line
        int <- myamph$info$internal[[1]]
        if (length(int) <= 4){
            myi <- which.max(unlist(lapply(myamph$info$internal[[1]], function(x) length(x))))
            int <- myamph$info$internal[[1]][[myi]]
            int <- as.data.frame(cbind(int[,,1],int[,,2]))
        } else {
            int <- as.data.frame(apply(int, 4, rbind))
        }
        names(int) <- c("X","Y")
        int <- Line(int)
        int <- Lines(list(int), ID=2)
        int <- SpatialLines(list(int))
        plot(int, col="darkred", add=TRUE)
    }
    
    if (length(myamph$info$midline[[1]]) > 1){
        # Build mlo midline line
        ml <- myamph$info$midline[[1]]
        if (length(ml) <= 4){
            myi <- which.max(unlist(lapply(myamph$info$midline[[1]], function(x) length(x))))
            ml <- myamph$info$midline[[1]][[myi]]
            ml <- as.data.frame(cbind(ml[,,1],ml[,,2]))
        } else {
            ml <- as.data.frame(apply(ml, 4, rbind))
        }
        names(ml) <- c("X","Y")
        ml <- Line(ml)
        ml <- Lines(list(ml), ID=2)
        ml <- SpatialLines(list(ml))
        plot(ml, col="black", add=TRUE)
    }
    
    if (length(myamph$info$neckjoin[[1]]) > 1){
        # Build njo neckjoin line
        nj <- myamph$info$neckjoin[[1]]
        if (length(nj) <= 4){
            myi <- which.max(unlist(lapply(myamph$info$neckjoin[[1]], function(x) length(x))))
            nj <- myamph$info$neckjoin[[1]][[myi]]
            nj <- as.data.frame(cbind(nj[,,1],nj[,,2]))
        } else {
            nj <- as.data.frame(apply(nj, 4, rbind))
        }
        names(nj) <- c("X","Y")
        nj <- Line(nj)
        nj <- Lines(list(nj), ID=2)
        nj <- SpatialLines(list(nj))
        plot(nj, col="grey75", add=TRUE)
    }
    
    if (length(myamph$info$lhandle[[1]]) > 1){
        # Build lho lhandle line
        lh <- myamph$info$lhandle[[1]]
        if (length(lh) <= 4){
            myi <- which.max(unlist(lapply(myamph$info$lhandle[[1]], function(x) length(x))))
            lh <- myamph$info$lhandle[[1]][[myi]]
            lh <- as.data.frame(cbind(lh[,,1],lh[,,2]))
        } else {
            lh <- as.data.frame(apply(lh, 4, rbind))
        }
        names(lh) <- c("X","Y")
        lh <- Line(lh)
        lh <- Lines(list(lh), ID=2)
        lh <- SpatialLines(list(lh))
        plot(lh, col="brown", add=TRUE)
    }
    
    if (length(myamph$info$rhandle[[1]]) > 1){
        # Build rho rhandle line
        rh <- myamph$info$rhandle[[1]]
        if (length(rh) <= 4){
            myi <- which.max(unlist(lapply(myamph$info$rhandle[[1]], function(x) length(x))))
            rh <- myamph$info$rhandle[[1]][[myi]]
            rh <- as.data.frame(cbind(rh[,,1],rh[,,2]))
        } else {
            rh <- as.data.frame(apply(rh, 4, rbind))
        }
        names(rh) <- c("X","Y")
        rh <- Line(rh)
        rh <- Lines(list(rh), ID=2)
        rh <- SpatialLines(list(rh))
        plot(rh, col="brown2", add=TRUE)
    }
    
    if (length(myamph$info$section[[1]]) > 1){
        # Build hso section line
        hs <- myamph$info$section[[1]]
        if (length(hs) <= 4){
            myi <- which.max(unlist(lapply(myamph$info$section[[1]], function(x) length(x))))
            hs <- myamph$info$section[[1]][[myi]]
            hs <- as.data.frame(cbind(hs[,,1],hs[,,2]))
        } else {
            hs <- as.data.frame(apply(hs, 4, rbind))
        }
        names(hs) <- c("X","Y")
        hs <- Line(hs)
        hs <- Lines(list(hs), ID=2)
        hs <- SpatialLines(list(hs))
        plot(hs, col="black", add=TRUE)
    }
    
    # Save a pdf summary
    dev.print(device=pdf, paste(TrDetails$Drawing[1],"/userchecks/",TrDetails$Drawing[1],"_user",TrDetails$UserID[a],".pdf", sep=""))
}
dev.off()

# Get metadata file and fill in.
myurl1 <- "http://micropasts-amphoras.s3.amazonaws.com/other/template_README.md"
myurl2 <- "http://micropasts-amphoras.s3.amazonaws.com/other/ads_coll463_details.csv"
download.file(URLencode(myurl1),paste(dr,"/",dr,"_README.md",sep=""))
download.file(URLencode(myurl2),paste(dr,"/userchecks/tmp.csv",sep=""))

# Sort out inputs.
mytypes <- read.csv(paste(dr,"/userchecks/tmp.csv",sep=""), header=TRUE, stringsAsFactors=FALSE)
mytype <- mytypes$Type[grepl(dr,mytypes$Drawing)]
myref <- mytypes$References[grepl(dr,mytypes$Drawing)]

# Load template metadata file and fill in blanks
mymetadata <- readLines(paste(dr,"/",dr,"_README.md",sep=""))
mymetadata <- gsub("AAAA",mytype,mymetadata)
mymetadata <- gsub("BBBB",dr,mymetadata)
mymetadata <- gsub("CCCC",myref,mymetadata)
mymetadata <- gsub("EEEE",whoami,mymetadata)

# If available, load user data (you would need to be provided with the user name file)
#http://crowdsourced.micropasts.org/admin/users/export?format=csv (when logged in as admin)
users <- read.csv(userfile, header=TRUE, stringsAsFactors=FALSE)
users <- users[,c("id","fullname","name")]
myusers <- paste(users$fullname[users$id %in% trTr$user_id],sep=", ", collapse=", ")
mymetadata <- gsub("DDDD",myusers,mymetadata)
# If you want to indicate that one contributor did most of the best work, you can add an asterisk by their name to the metadata file manually afterwards.

# Write out metadata and remove temporary file.
writeLines(mymetadata,paste(dr,"/",dr,"_README.md",sep=""))
file.remove(paste(dr,"/userchecks/tmp.csv",sep=""))
