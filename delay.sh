#!/usr/bin/env bash

if ! command -v curl &>/dev/null; then
	echo -e "'curl' is missing, install it by running:\n\n\t sudo apt-get install curl"
	exit
fi

if ! command -v jq &>/dev/null; then
	echo -e "'jq' is missing, install it by running:\n\n\t sudo apt-get install jq"
	exit
fi

SORTBY=".delay"
PRESENTATION_FILTER="."
THRESHOLD=19
while getopts sadtm: opt; do
	case $opt in
	a) SORTBY=".actual" ;;
	d) SORTBY=".delay" ;;
	s) SORTBY=".should" ;;
	t) PRESENTATION_FILTER="[ group_by(.link) | .[] | max_by(.delay) ]" ;;
	m) THRESHOLD=$((OPTARG)) ;;
	\?)
		echo "Unknown option -$OPTARG"
		exit 1
		;;
	esac
done

tempfile=$(mktemp)
cat <<'EOT' >${tempfile}
def duration($finish; $start):
  [$finish, $start]
  | map(.[:-10])
  | map(strptime("%FT%T") | mktime) # seconds
  | .[0] - .[1]
  | (. % 60) as $s
  | (. / 60) as $m
  | $m
  | floor ;

.RESPONSE.RESULT
  | .[0]
  | .TrainAnnouncement
  | .[]
  | select ( .ActivityType == "Ankomst" )
  | select ( .ProductInformation[0].Description != "SJ Snabbtåg" )
  | select ( .ProductInformation[0].Description != "SJ Nattåg" )
  | select ( .Advertised == true )
  | select ( .TimeAtLocation[:10] == $today ) # only check date YYYY-MM-dd
  | {
    owner: .TrainOwner,
    canceled: .Canceled,
    delay: duration(.TimeAtLocation; .AdvertisedTimeAtLocation),
    should: .AdvertisedTimeAtLocation[11:-13], # only display HH:mm
    actual: .TimeAtLocation[11:-13], # only display HH:mm
    location: $trainStationsInVG[.LocationSignature],
    path: "\($trainStations[.FromLocation[0].LocationName]) - \($trainStations[.ToLocation[0].LocationName])",
    link: "https://www.trafikverket.se/trafikinformation/tag/?Train=\(.AdvertisedTrainIdent)"
  }
  | select ( .location != null )
  | select ( .delay >= ( $threshold | tonumber ) or .canceled )
  | if (.canceled) then del (.delay, .actual) else del (.canceled) end
EOT

trainStationsInVG=$(curl -s 'https://api.trafikinfo.trafikverket.se/v2/data.json' -X POST \
	-H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:93.0) Gecko/20100101 Firefox/93.0' \
	-H 'Accept: application/json, text/javascript, */*; q=0.01' \
	-H 'Accept-Language: en-US,en;q=0.5' --compressed \
	-H 'Referer: https://www.trafikverket.se/' \
	-H 'Content-Type: text/xml' \
	-H 'cache-control: no-cache' \
	-H 'Origin: https://www.trafikverket.se' \
	-H 'Connection: keep-alive' \
	-H 'Sec-Fetch-Dest: empty' \
	-H 'Sec-Fetch-Mode: cors' \
	-H 'Sec-Fetch-Site: same-site' \
	-H 'TE: trailers' \
	--data-raw $'<REQUEST><LOGIN authenticationkey=\'707695ca4c704c93a80ebf62cf9af7b5\'/><QUERY  lastmodified=\'false\' objecttype=\'TrainStation\' schemaversion=\'1\' includedeletedobjects=\'false\' sseurl=\'false\'><FILTER></FILTER></QUERY></REQUEST>' |
	jq -c '.RESPONSE.RESULT | .[0] | .TrainStation | .[] | select (.CountyNo[0] == 14) | [{(.LocationSignature): .AdvertisedLocationName}] | add ' |
	jq -s -r -M add)

trainStations=$(curl -s 'https://api.trafikinfo.trafikverket.se/v2/data.json' -X POST \
	-H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:93.0) Gecko/20100101 Firefox/93.0' \
	-H 'Accept: application/json, text/javascript, */*; q=0.01' \
	-H 'Accept-Language: en-US,en;q=0.5' --compressed \
	-H 'Referer: https://www.trafikverket.se/' \
	-H 'Content-Type: text/xml' \
	-H 'cache-control: no-cache' \
	-H 'Origin: https://www.trafikverket.se' \
	-H 'Connection: keep-alive' \
	-H 'Sec-Fetch-Dest: empty' \
	-H 'Sec-Fetch-Mode: cors' \
	-H 'Sec-Fetch-Site: same-site' \
	-H 'TE: trailers' \
	--data-raw $'<REQUEST><LOGIN authenticationkey=\'707695ca4c704c93a80ebf62cf9af7b5\'/><QUERY  lastmodified=\'false\' objecttype=\'TrainStation\' schemaversion=\'1\' includedeletedobjects=\'false\' sseurl=\'false\'><FILTER></FILTER></QUERY></REQUEST>' |
	jq -c '.RESPONSE.RESULT | .[0] | .TrainStation | .[] | [{(.LocationSignature): .AdvertisedLocationName}] | add ' |
	jq -s -r -M add)

trainStationsInVGFilter=$(echo $trainStationsInVG | jq --raw-output 'keys | .[] | "<EQ name='\''LocationSignature'\'' value='\''\(.)'\''/>"' | tr '\n' ' ')

curl -s 'https://api.trafikinfo.trafikverket.se/v2/data.json' \
	-H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:90.0) Gecko/20100101 Firefox/90.0' \
	-H 'Accept: application/json, text/javascript, */*; q=0.01' \
	-H 'Accept-Language: en-US,en;q=0.5' --compressed \
	-H 'Referer: https://www.trafikverket.se/' \
	-H 'Content-Type: text/xml' \
	-H 'cache-control: no-cache' \
	-H 'Origin: https://www.trafikverket.se' \
	-H 'Connection: keep-alive' \
	-H 'Sec-Fetch-Dest: empty' \
	-H 'Sec-Fetch-Mode: cors' \
	-H 'Sec-Fetch-Site: same-site' \
	-H 'TE: trailers' \
	--data-raw "<REQUEST><LOGIN authenticationkey='707695ca4c704c93a80ebf62cf9af7b5'/><QUERY runtime='true' lastmodified='true' objecttype='TrainAnnouncement' schemaversion='1.6' includedeletedobjects='false' sseurl='true'><FILTER><AND><OR>${trainStationsInVGFilter}</OR> <EQ name='ScheduledDepartureDateTime' value='$(date +%F)T00:00:00+01:00'/><OR><EQ name='TrainOwner' value='VASTTRAF'/> <EQ name='TrainOwner' value='SJ'/> </OR></AND></FILTER></QUERY></REQUEST>" |
	jq --argjson trainStations "${trainStations}" --argjson trainStationsInVG "${trainStationsInVG}" --arg today "$(date +%F)" --arg threshold $((THRESHOLD)) -f "${tempfile}" |
	jq -s "${PRESENTATION_FILTER} | sort_by(${SORTBY})" &
pid=$! # Process ID of the previous command
spin='◐◓◑◒'
i=0
while kill -0 $pid 2>/dev/null; do
	i=$(((i + 1) % 4))
	printf "\r${spin:$i:1} Working!"
	sleep .1
done
rm "${tempfile}"
