## install.packages("RAmazonS3", repos = "http://www.omegahat.org/R", type = "source")
library(RAmazonS3)

# List all buckets
listBuckets(auth = c('insertlogin' = 'insertsecret'))

# List files in bucket
mybucket <- "pilgrim-badges"
mybucketcontents <- listBucket(mybucket, auth=c('insertlogin' = 'insertsecret'))

# Create full URLs
myurls <-paste("http://",mybucket,".s3.amazonaws.com/",mybucketcontents[,1],sep="")
myurls # worth pasting oneof these n browser to check permissions and links work.

#Put into Pybossa firendly format and write out.
urldf <- data.frame(url_b=myurls)
write.csv(urldf, file="myurls.csv", row.names=FALSE)

# At the moment you either have to put this csv online somewhere (e.g. AmazonS3, dropbox etc and pass Pybossa the url or copyy and paste it into a google spreadsheet.
