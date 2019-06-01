#!/bin/bash
# Script to take the log file from OpenAPS autosense and reformat it into a Nightscout-compatible json for upload
# Edward J. Oakeley, v0.2, 01-Jun-2019
# Feel free to reuse however you like, don't even care if you claim it as your own. I give it to the community but I reserve the right to ignore requests to support it
#WeAreNotWaiting
# syntax: sh fixprofile.sh http://myNightscout.com myAPIsecret
# Get the download script
ls ~/myopenaps/nightscout/ 2> test; cat test | awk '{ if($2=="cannot") {system("mkdir ~/myopenaps/nightscout/; cd ~/myopenaps/nightscout/; wget https://raw.githubusercontent.com/viq/oref0/profile_from_nightscout/bin/get_profile.py")} }'
rm test
echo "{" > new.json
echo "    \"min_5m_carbimpact\": 8.0," >> new.json
# Pull "dia" from Nightscout
python2 ~/myopenaps/nightscout/get_profile.py --nightscout $1 display --format openaps --name 'OpenAPS Autosync' | grep dia >> new.json
#echo "    \"dia\": 5," >> new.json
echo "    \"basalprofile\": [" >> new.json
# Pull all the suggestions out of the autotune log
cat ~/myopenaps/autotune/autotune_recommendations.log | awk -F"|" '{ print $1 "[" $3 }' | tr -d " " | grep ":" | awk -F"[" -v n="0" '{ if(length($0)>6) {print "        {"; print "            \"i\": "n","; n+=1; print "            \"start\": \"" $1 ":00\","; split($1,a,":"); b=(a[1]*60)+a[2]; print "            \"minutes\": " b ","; print "            \"rate\": " $2; print "        }," } }' | sed '$ s/.$//' >> new.json
echo "    ]," >> new.json
# copy the glucose targets from Nightscout. If this doesn't work for you then comment the next line and uncomment the one after
python2 ~/myopenaps/nightscout/get_profile.py --nightscout $1 display --format openaps --name 'OpenAPS Autosync' | awk -v go="True" '{ if(go=="True") {print $0; if(length($0)==7) {go="False"} } }' >> new.json
## You can't upload to Nightscout without bg_targets. YOU MUST CHANGE "mmol" to "mg/dl" if you are American/German/want other units. The low/high settngs are hard coded for me. I will fix this if I can ever figure out how to download from Nightscout
#echo "" | awk '{print "    \"bg_targets\": {"; print "        \"units\": \"mmol\","; print "        \"user_preferred_units\": \"mmol\","; print "        \"targets\": ["; print "            {"; print "                \"i\": 0,"; print "                \"start\": \"00:00:00\","; print "                \"offset\": 0,"; print "                \"low\": 5,"; print "                \"min_bg\": 5,"; print "                \"high\": 8,"; print "                \"max_bg\": 8"; print "            },"; print "            {"; print "                \"i\": 1,"; print "                \"start\": \"07:00:00\","; print "                \"offset\": 25200,"; print "                \"low\": 4,"; print "                \"min_bg\": 4,"; print "                \"high\": 6.5,"; print "                \"max_bg\": 6.5"; print "            }"; print "        ]"; print "    },";}' >> new.json
echo "    \"isfProfile\": {" >> new.json
echo "        \"sensitivities\": [" >> new.json
echo "            {" >> new.json
echo "                \"i\": 0," >> new.json
echo "                \"start\": \"00:00:00\"," >> new.json
# Pull the ISF from the logs
cat /home/edward/myopenaps/autotune/autotune_recommendations.log | grep ISF | tr -d " " | awk -F"|" '{ print "                \"sensitivity\": "$3"," }' >> new.json
echo "                \"offset\": 0," >> new.json
echo "                \"x\": 0," >> new.json
echo "                \"endOffset\": 1440" >> new.json
echo "            }" >> new.json
echo "        ]" >> new.json
echo "    }," >> new.json
# Pull the carb ratio from the logs
cat /home/edward/myopenaps/autotune/autotune_recommendations.log | grep Carb | tr -d " " | awk -F"|" '{print "    \"carb_ratios\": {"; print "        \"first\": 1,"; print "        \"units\": \"grams\","; print "        \"schedule\": ["; print "            {"; print "                \"i\": 0,"; print "                \"start\": \"00:00:00\","; print "                \"offset\": 0.0,"; print "                \"ratio\": " $3; print "            }"; print "        ]"; print "    },"; print "    \"carb_ratio\": "$3"," }' >> new.json
echo "    \"autosens_max\": 1.2," >> new.json
echo "    \"autosens_min\": 0.7" >> new.json
echo "}" >> new.json
# rename everything
mv profile.json old.json
cp new.json profile.json
cp new.json autotune.json
cp new.json pumpprofile.json
cd ~/myopenaps; oref0-upload-profile settings/profile.json $1 $2
echo "done"

