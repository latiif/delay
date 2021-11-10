# Delay

Delay is a bash script for querying and listing [refundable](https://www.vasttrafik.se/kundservice/forseningsersattning) train delays in [Västra Götaland, Sweden](https://en.wikipedia.org/wiki/V%C3%A4stra_G%C3%B6taland_County).

## Installation

Clone the repository, or just copy the raw `delay.sh` file.

## Requirements

The script is stand-alone, and comes with instructions on installing the necessary software:

* [jq](https://stedolan.github.io/jq/) for manipulating JSON objects.
* [curl](https://curl.se/) for querying back-end API's.

## Usage

If you copied the raw file, you first need to mark the script as executable:

```bash
chmod +x delay.sh
```

Then you can simply run:

```bash
./delay.sh
```

And you'll get:

```json
[{
        "owner": "VASTTRAF",
        "delay": 19,
        "should": "08:15",
        "actual": "08:34",
        "location": "Göteborg C",
        "path": "Åmål - Göteborg C",
        "link": "https://www.trafikverket.se/trafikinformation/tag/?Train=13297"
    },
    {
        "owner": "SJ",
        "delay": 22,
        "should": "18:46",
        "actual": "19:08",
        "location": "Åmål",
        "path": "Göteborg C - Kristinehamn",
        "link": "https://www.trafikverket.se/trafikinformation/tag/?Train=372"
    },
    {
        "owner": "SJ",
        "delay": 25,
        "should": "17:51",
        "actual": "18:16",
        "location": "Trollhättan C",
        "path": "Göteborg C - Kristinehamn",
        "link": "https://www.trafikverket.se/trafikinformation/tag/?Train=372"
    },
    {
        "owner": "SJ",
        "delay": 26,
        "should": "17:57",
        "actual": "18:23",
        "location": "Öxnered",
        "path": "Göteborg C - Kristinehamn",
        "link": "https://www.trafikverket.se/trafikinformation/tag/?Train=372"
    },
    {
        "owner": "SJ",
        "delay": 28,
        "should": "18:17",
        "actual": "18:45",
        "location": "Mellerud",
        "path": "Göteborg C - Kristinehamn",
        "link": "https://www.trafikverket.se/trafikinformation/tag/?Train=372"
    }
]
```

And this will print out all arrival delays that are more than `19` minutes of trains run by SJ, Västtrafik and are refundable. By default the results are sorted by delay (inc).

To sort results chronologically by actual time of arrival, run `./delay.sh -a`; to sort delays by their scheduled time of arrival, run: `./delay.sh -s`.

### Aggregate delays by train

Most train that are delayed by more than `19` minutes will be delayed at multiple stations, that's why you can use `./delay.sh -t` to remove the clutter and only display the delay information once per train.

The delay occasion will be the one with the biggest delay.

```bash
./delay.sh -t
```

which will result in:

```json
{
  "owner": "VASTTRAF",
  "delay": 19,
  "should": "08:15",
  "actual": "08:34",
  "location": "Göteborg C",
  "path": "Åmål - Göteborg C",
  "link": "https://www.trafikverket.se/trafikinformation/tag/?Train=13297"
}
{
  "owner": "SJ",
  "delay": 28,
  "should": "18:17",
  "actual": "18:45",
  "location": "Mellerud",
  "path": "Göteborg C - Kristinehamn",
  "link": "https://www.trafikverket.se/trafikinformation/tag/?Train=372"
}

```

## License

All rights reserved to Abdullatif _Latiif_ Alshriaf.
