# fixprofile
Script to take the log file from OpenAPS autosense and reformat it into a Nightscout-compatible json for upload

This now pulls the glucose targets from Nightscout and merges them with the new autotune data.
According to viq none of this is needed so maybe this is of no use but hey, use it if it helps.
It is all done in BASH so pretty easy and no real dependencies. Viq's python script depends on a few pip installs. If you get errors then try: sudo pip install texttable requests
