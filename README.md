# Weather
Command line tool to get the weather forecast

## Usage:
```
weather [location] [forecast type]

e.g.
weather // Get current weather at your current location
weather here now // ...

weather london tomorrow // Get tomorrow's weather in London

weather "new york" week // Get New York's weather for the next 5 days
```
## Example:
![Image of example usage](https://media.discordapp.net/attachments/496681934370635787/660627411318341662/unknown.png?width=1154&height=628)

## Building From Source
Requires OpenWeatherMap API key defined as `WEATHER_API_KEY`

```
# Clone repo
$ git clone https://github.com/a-vorontsov/weather
$ cd weather

# Install dependencies
$ nimble install -d

# Build binary
$ nim c -d:ssl --verbosity:0 -d:release --app:console --putenv:WEATHER_API_KEY=$WEATHER_API_KEY src/weather.nim

# Install binary
$ sudo cp ./weather /usr/local/bin/weather
