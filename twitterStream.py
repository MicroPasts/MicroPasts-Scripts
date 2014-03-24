# Slightly modified version of script found here: http://www.quartertothree.com/game-talk/showthread.php?73978-Data-mining-Twitter-for-sentiments-about-the-new-consoles&s=1a4b8987a11613f877342eaa1adc28f7&p=3479467&viewfull=1#post3479467
# Import the libraries that we need
from twython import TwythonStreamer
import json
import csv
import re

# These are the keys for your twitter application, as discussed earlier in the tutorial
APP_KEY            = 'API_KEY'
APP_SECRET         = 'API_SECRET'
OAUTH_TOKEN        = 'OAUTH token'
OAUTH_TOKEN_SECRET = 'OAUTH SECRET'

# Prompt the user for the terms to track
track_terms = '#museumweek,#museumselfie,#museumselfies,#dayinthelife,#museummastermind,#museummemories,#behindtheart,#askthecurator,#getcreative'

# Prompt the user for how many tweets they want to keep
keep_tweets = int(-1)

# Adjust the input number
if keep_tweets < 0:
    keep_tweets = 999999999
elif keep_tweets == 0:
    keep_tweets = 10

# This will cause the script to keep only english language tweets
# Change to 'all' to keep all tweets regardless of language
keep_lang = 'all'

# Counter for keeping track how many tweets we've saved
counter = 0

# Variable to track whether we've written the header to the CSV file
header_done = False

# Variable to use to name sequential files full of tweets
file_name_suffix = 0

# Prompt the user for how many tweets they want per sequential file
tweets_per_file = int(10000)

if tweets_per_file <= 0:
    tweets_per_file = 50000

# This class will process incoming tweets and is called from MyStreamer
# in the on_success() method
class TweetMonkey:
    # Remove some nasty characters that can break the CSV
    def clean(self,text):
        text = text.replace("\n","; ")
        text = text.replace('"', "'")
        text = text.replace(','," ")
        return text

    # Method to create the CSV header in each file
    def create_header(self):
	global file_name_suffix

        header = []
        header.append("id")
        header.append("lang")
        header.append("user_name")
        header.append("screen_name")
        header.append("tweet")
        header.append("retweeted")
        header.append("retweet_count")
        header.append("favorite_count")
        header.append("source")
        header.append("in_reply_to_status_id")
        header.append("in_reply_to_screen_name")
        header.append("in_reply_to_user_id")
        header.append("possibly_sensitive")
        header.append("geo")
        header.append("created_at")

        # Write the header to the file
        tweets = open("tweetsmuseum_" + str(file_name_suffix) + ".csv", 'ab+')
        wr     = csv.writer(tweets, dialect='excel')
        wr.writerow(header)
        tweets.close()

    # This is the method that does the heavy lifting for processing a tweet
    # and putting it into the CSV file
    def process(self, tweet):
        global header_done
        global file_name_suffix
        global counter
        global tweets_per_file

        if counter % 1000 == 0:
            print counter, "tweets processed..."

        # Increment the file name 
        if counter % tweets_per_file == 0:
            file_name_suffix += 1
            header_done = False # reenable if you want every file to include the header

        if not header_done:
            self.create_header()
            header_done = True

        # Create the file or append to the existing
        #You can get the list of fields returned by the response here: https://gist.github.com/hrp/900964
        theOutput = []

        theOutput.append(           tweet['id'])
        theOutput.append(           tweet['lang'].encode('utf-8'))

        # There is redundant scrubbing of the username because I was
        # having trouble removing all of the \n characters
        uname = tweet['user']['name'].encode('utf-8', 'replace')
        newuname = re.sub('\n','',uname)
        theOutput.append(           newuname)
        theOutput.append(           tweet['user']['screen_name']

        # There is redundant scrubbing of the tweet because I was
        # having trouble removing all of the \n characters
        twt = self.clean(tweet['text']).encode('utf-8', 'replace')
        newtwt = re.sub('\n','',twt)
        theOutput.append(newtwt)
        
        theOutput.append(           tweet['retweeted'])
        theOutput.append(           tweet['retweet_count'])
        theOutput.append(           tweet['favorite_count'])
        theOutput.append(self.clean(tweet['source']).encode('utf-8', 'replace'))
        theOutput.append(           tweet['in_reply_to_status_id'])
        theOutput.append(           tweet['in_reply_to_screen_name'])
        theOutput.append(           tweet['in_reply_to_user_id'])

        if tweet.get('possibly_sensitive'):
            theOutput.append(       tweet['possibly_sensitive'])
        else:
            theOutput.append("False")

        if tweet['geo'] is not None:
            if tweet['geo']['type'] == 'Point':
                lat = str(tweet['geo']['coordinates'][0]) + " "
                lon = str(tweet['geo']['coordinates'][1])
                theOutput.append(lat + lon)
            else:
                theOutput.append(tweet['geo'])
        else:
            theOutput.append(tweet['geo'])
        theOutput.append(tweet['created_at'])

        # Write the tweet to the CSV File
        tweets = open("tweetsmuseum_" + str(file_name_suffix) + ".csv", 'ab+')
        wr     = csv.writer(tweets, dialect='excel')
        wr.writerow(theOutput)
        tweets.close()

# This is the subclass of TwythonStreamer that handles incoming tweets
class MyStreamer(TwythonStreamer):
    # Do this if the tweet is successfully captured
    def on_success(self, data):
        global counter
        global keep_lang
        global keep_tweets
        if 'text' in data:
            if keep_lang == 'all' or data['lang'] == keep_lang:
                # Uncomment this if you want to keep the JSON in a single file
                # g = open("games.json", "ab+")
                # json.dump(data,g)
                # g.write("\n")
                # g.close()

                # Keep the CSV
                counter += 1
                writer   = TweetMonkey()
                writer.process(data)

        # Disconnect when we have the number of requested tweets
        if counter >= keep_tweets:
            self.disconnect()
            print "All done."

    # Do this if there's an error with the tweet
    def on_error(self, status_code, data):
        print "There was an error:\n"
        print status_code, data

# Create an instance of the MyStreamer class 
stream = MyStreamer(APP_KEY,APP_SECRET,OAUTH_TOKEN,OAUTH_TOKEN_SECRET)

# Tell the instance of the MyStreamer class what you want to track
stream.statuses.filter(track=track_terms)
