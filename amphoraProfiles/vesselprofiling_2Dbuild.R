######

# This script only downloads and processes one vessel outline at a time. You need to know the app name and task ID of the amphora you want, and you must specify the ID of a particular contributor to that task (typical usage) or (be careful) you can ask for the contirbutions of different users to be combined.

# The script will produce several kinds of output: (a) a clean 2d shapefile with attributes that distinguish different vessels parts, (b) a similar shapefile but with handles left overlapping the body for ease of 3d modelling modelling, (c) a pdf plot of the vessel as a guide to the quality of the output.

# The script is meant to be run after having run a set of user checks with vesselprofiling_userchecks.R. It is also meant as a pre-cursor to the vesselprofiling_3Dblend.py Blender script. These three scripts together constitute a complete workflow.

# Andy Bevan 03-March-2015

######

# Set-up (things you can change)
setwd("~/Documents/research/micropasts/analysis/amphs/examples") #MacOSX
appname <- "amphs1" #the app from which you wish to extract an outline.
taskID <- 31370 #which task you want to model.
userID <- 873 #to specify a particular contributor.
#Use the parameters below if you wish to mix-and-match, otherwise don't touch.
userdf <- data.frame(ScaleBarUser=userID,DimensionUser=userID,ExternalUser=userID, InternalUser=userID,MidLineUser=userID,NeckJoinUser=userID,LHandleUser=userID,RHandleUser=userID, SectionUser=userID)


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

######

## Polygon Build Steps ##

# Build into external polygon
myamph <- trTr[trTr$user_id == as.character(userdf$ExternalUser),, drop=FALSE]
ext <- myamph$info$external[[1]]
ext <- as.data.frame(apply(ext, 4, rbind))
names(ext) <- c("X","Y")
ext <- Polygon(ext)
ext <- Polygons(list(ext), ID=1)
ext <- SpatialPolygons(list(ext))
# Build into internal polygon
myamph <- trTr[trTr$user_id == as.character(userdf$InternalUser),, drop=FALSE]
int <- myamph$info$internal[[1]]
int <- as.data.frame(apply(int, 4, rbind))
names(int) <- c("X","Y")
int <- Polygon(int)
int <- Polygons(list(int), ID=2)
int <- SpatialPolygons(list(int))
# Build mid-line polygon
myamph <- trTr[trTr$user_id == as.character(userdf$MidLineUser),, drop=FALSE]
ml <- myamph$info$midline[[1]]
ml <- as.data.frame(apply(ml, 4, rbind))
names(ml) <- c("X","Y")
ml <- Polygon(ml)
ml <- Polygons(list(ml), ID=3)
ml <- SpatialPolygons(list(ml))
# Build neck-join polygon
myamph <- trTr[trTr$user_id == as.character(userdf$NeckJoinUser),, drop=FALSE]
nj <- myamph$info$neckjoin[[1]]
nj <- as.data.frame(apply(nj, 4, rbind))
names(nj) <- c("X","Y")
nj <- Polygon(nj)
nj <- Polygons(list(nj), ID=4)
nj <- SpatialPolygons(list(nj))
# Build left-handle polygon
myamph <- trTr[trTr$user_id == as.character(userdf$LHandleUser),, drop=FALSE]
lh <- myamph$info$lhandle[[1]]
lh <- as.data.frame(apply(lh, 4, rbind))
names(lh) <- c("X","Y")
lh <- Polygon(lh)
lh <- Polygons(list(lh), ID=3)
lh <- SpatialPolygons(list(lh))
# Build right-handle polygon
myamph <- trTr[trTr$user_id == as.character(userdf$RHandleUser),, drop=FALSE]
rh <- myamph$info$rhandle[[1]]
rh <- as.data.frame(apply(rh, 4, rbind))
names(rh) <- c("X","Y")
rh <- Polygon(rh)
rh <- Polygons(list(rh), ID=3)
rh <- SpatialPolygons(list(rh))
# Build handle section
myamph <- trTr[trTr$user_id == as.character(userdf$SectionUser),, drop=FALSE]
hs <- myamph$info$section[[1]]
hs <- as.data.frame(apply(hs, 4, rbind))
names(hs) <- c("X","Y")
hs <- Polygon(hs)
hs <- Polygons(list(hs), ID=7)
hs <- SpatialPolygons(list(hs))
hs <- SpatialPolygonsDataFrame(hs, data.frame(Type="Handle section", row.names="7"))
# Clip external space
allext <- ext
allext <- spChFIDs(allext,"0")
allext <- SpatialPolygonsDataFrame(allext, data.frame(Type="All", row.names="0"))
ext <- gDifference(ext,ml)
ext <- gDifference(ext,int)
ext <- spChFIDs(ext,"1")
ext <- SpatialPolygonsDataFrame(ext, data.frame(Type="External", row.names="1"))
# Clip internal space
int <- gIntersection(int,allext)
int <- gDifference(int,ml)
int <- gDifference(int,nj)
int <- spChFIDs(int,"2")
int <- SpatialPolygonsDataFrame(int, data.frame(Type="Internal", row.names="2"))
# Clip neck-join space
nj <- gIntersection(nj,allext)
nj <- gDifference(nj,ml)
nj <- gDifference(nj,int)
nj <- spChFIDs(nj,"4")
nj <- SpatialPolygonsDataFrame(nj, data.frame(Type="Neck join", row.names="4"))
# Clip handle
rhb <- rh #back-up for Blender version
lhb <- lh #back-up for Blender version
lh <- gDifference(lh,allext)
rh <- gDifference(rh,allext)
lh <- spChFIDs(lh,"5")
rh <- spChFIDs(rh,"6")
lhb <- spChFIDs(lhb,"5")
rhb <- spChFIDs(rhb,"6")
lh <- SpatialPolygonsDataFrame(lh, data.frame(Type="Left Handle", row.names="5"))
rh <- SpatialPolygonsDataFrame(rh, data.frame(Type="Right Handle", row.names="6"))
lhb <- SpatialPolygonsDataFrame(lhb, data.frame(Type="Left Handle", row.names="5"))
rhb <- SpatialPolygonsDataFrame(rhb, data.frame(Type="Right Handle", row.names="6"))
# Combine into one object
amph <- spRbind(allext,ext)
amph <- spRbind(amph,int)
amph <- spRbind(amph,nj)
amphB <- amph
amph <- spRbind(amph,lh)
amph <- spRbind(amph,rh)
amph <- spRbind(amph,hs)
amphB <- spRbind(amphB,lhb)
amphB <- spRbind(amphB,rhb)
amphB <- spRbind(amphB,hs)

#Assuming the amphora on the scanned drawing may not be exactly upright, work out how much to rotate the drawing by. Two methods, either by looking at the midline angle or by checking a range of rotations within the range -20 to 20 deg of vertical for the one that minimises the are of the 'allext' bounding box.
# Method 1
mlcoords <- as.data.frame(ml@polygons[[1]]@Polygons[[1]]@coords)
mlcoords <- mlcoords[-nrow(mlcoords),]
mlcoords <- mlcoords[with(mlcoords, order(X)), ]
a <- mlcoords[1,]
b <- mlcoords[1,]
theta <- acos( sum(a*b) / ( sqrt(sum(a * a)) * sqrt(sum(b * b)) ) )
prefrot <- -1*theta
# Method 2
## rots <- seq(-20,20,0.1)
## amphht <- abs(bbox(allext)[2,1] - bbox(allext)[2,2])
## amphwd <- abs(bbox(allext)[1,1] - bbox(allext)[1,2])
## ampharea <- amphht*amphwd
## minarea <- ampharea
## for (a in 1: length(rots)){
##     allcheck <- elide(allext, rotate=rots[a], center=apply(bbox(allext), 1, mean))
##     thisht <- abs(bbox(allcheck)[2,1] - bbox(allcheck)[2,2])
##     thiswd <- abs(bbox(allcheck)[1,1] - bbox(allcheck)[1,2])
##     thisarea <- thisht*thiswd
##     if (thisarea < minarea){
##         minarea <- thisarea
##         prefrot <- rots[a]
##     }
## }

#Rotate
amph <- elide(amph, rotate=prefrot, center=apply(bbox(allext), 1, mean))
amphB <- elide(amphB, rotate=prefrot, center=apply(bbox(allext), 1, mean))

# Re-scale
# Use the scalebar, scalebar measurement and height of unscaled allext to work out a target height for the amphora and scale to this. Extract the scalebar and dimension and use these plus the height of the amphora outline to establish the amphora's target height.
sb <- myamph$info$scalebar[[1]]
sb <- data.frame(X=sb[,,1],Y=sb[,,2])
sblength <- as.numeric(dist(sb))
dimension <- myamph$info$dimension
# Create target height and re-scale
conv <- dimension / sblength
amphht <- abs(bbox(amph[amph$Type=="All",])[2,1] - bbox(amph[amph$Type=="All",])[2,2])
trght <- amphht*conv
amph <- elide(amph, scale=trght)
amphB <- elide(amphB, scale=trght)

# Re-centre
# Move the amphora so its outline is centred on 0,0 in the XY plane.
xshift <- 0-mean(bbox(amph[amph$Type=="All",])[1,])
yshift <- 0-mean(bbox(amph[amph$Type=="All",])[2,])
amph <- elide(amph, shift=c(xshift,yshift))
amphB <- elide(amphB, shift=c(xshift,yshift))

######

## Export Outputs ##

# Work out the drawing name:
drurl <- trTr[1,]$info$img
dr <- strsplit(drurl,"/")[[1]]
dr <- dr[length(dr)]
dr <- strsplit(dr,"[.]")[[1]][1]

# Assuming the drawing directory already exists, create a sub-directory in it:
dir.create(paste(dr,"/build2D",sep=""))

# Export as shapefile
writeOGR(amph, dsn=paste(dr,"/build2D/",dr,"_2Dpoly", sep=""), layer="DR356_2Dpoly", driver="ESRI Shapefile", overwrite_layer=TRUE)
writeOGR(amphB, dsn=paste(dr,"/build2D/",dr,"_forBlender", sep=""), layer="DR356_forBlender", driver="ESRI Shapefile", overwrite_layer=TRUE)

# Save a pdf summary
dev.new(device=pdf, height=6, width=4)
plot(amph[amph$Type=="All",], col="bisque4", axes=TRUE)
plot(amph[amph$Type=="Left Handle",], col="brown", add=TRUE)
plot(amph[amph$Type=="Right Handle",], col="brown2", add=TRUE)
plot(amph[amph$Type=="Handle section",], col="black", add=TRUE)
plot(amph[amph$Type=="Internal",], col="darkred", add=TRUE)
plot(amph[amph$Type=="Neck join",], col="grey75", add=TRUE)
plot(amph[amph$Type=="External",], col="black", add=TRUE)
dev.print(device=pdf, paste(dr,"/build2D/",dr,".pdf", sep=""))
dev.off()

