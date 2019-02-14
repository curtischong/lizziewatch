# Lizzie watch

<p align="center">
  <img src="http://chongcurtis.com/photos/inner_lizzie.gif" alt="A photo of the proposed locations."/>
</p>

I entered college believing I could finally siphon time away from school and work on a few passion projects. Unfortunately, assignment after assignment quickly proved otherwise. So to save time, I’m working an AI to:

  * Estimate how long tasks take.
  * Evaluate the emotional impact calendar events have on my day.
  * Tell me to take a breath before I say things I immediately want to take back.
  * Choose the best song on Spotify to get me into the zone.

So far, I’ve built a Golang server that archives biometric data from an Apple Watch, pulls data from all of my calendar events, to do lists, and messenger conversations into a central InfluxDB database.

To record how different events shape my mood, I use the app to create a labelled dataset of how different events affect my bimetrics and mood. When an event happens, I pull up the app and crop the timeline that describes when the event happened. Then I tag the event with any of Robert Plutchik’s eight basic emotions (Fear, Joy, Anger, Sadness, Disgust, Suprise, Contempt, Interest) and ramble on about what happened in a comment box before sending the data to my server.

To top off the entire project, these services are protected under my OpenVPN network to keep those who want to run `DROP MEASUREMENT bioSamples` at bay.

To move the project forward, I’m building dashboard services to query my data in a chrome extension so I can see metadata about my life every time I open a new tab.

### Technical Things:

*disclaimer: this repo was adapted from https://github.com/thomaspaulmann/HeartControl by Thomas Paulmann. His base repo fixed a fundamental authentication error I had as I was developing the app*

Lizzie's WatchOS app is the core of my emotional database. By taking advantage of Apple's workouts API, I am able to query for a sample every 5 seconds... compared to healthkit's default of 5/10 minutes.
### Core Features
 - Data collection
     - This app features a robust syncing mechanism to get the data off the watch, onto the app, and into Lizzie herself.
 - Important Event archival
     - When a significant event occurs I will tell the phone what happened and carefully crop the moment to tell Lizzie how my biometrics were affected leading up to the event and after the event

Please note:
I rushed this project out in a week because I only have so much time to learn the entire ios + watch stack. For a side (but important!) component of Lizzie as a whole, I will knock out these todo list items in the future.
Note: you'll notice that for most of the code I'ver separated biosample and markevent code into different functions even though some functions could probably have been combined.
This was done intentionally because I couldn't find a way to pass a parameter to specify a variable predicate. Yeah, the CoreData API (and tbh the WatchConnectivity) API is buggy :/

### Todo
 - Refactor the ViewControllers
   - Move coreData scripts into it's own script (for the watch and phone)
 - add tests
 - better error logs
 - have the workout manager switch between running / normal activity (so the watch can adjust the sensors for better readings
