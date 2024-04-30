# Tracker

The Tracker project is a example application to demonstrate the use of the Riot Games API.

The main function is Tracker.track_summoner/2 which will generate a list of all summers that have played with the current summoner in their last 5 matches.

All summoners are then tracked for the next 60 minutes to log any new games they have completed. The Riot api is polled every 60 seconds.

Users must have a Riot Games Developer Account and API key.

Add your non-expired api key to the /config/config.exs file.

To use the app clone the repository and start the project with iex -S mix, then call Tracker.track_summoner/2 with the gameName and tagLine of the summoner you wish to track.
