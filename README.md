# Lizzie watch
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
