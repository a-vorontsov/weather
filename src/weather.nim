when isMainModule:
    import httpclient, times, os, strformat, json, strutils, nap, re,
            colorize, sequtils, table, math, rdstdin, util, distros

    const WEATHER_API_KEY = os.getEnv("WEATHER_API_KEY")
    var locationPermissions = false
    var locationCity: string
    var disableColour = false

    proc ctrlc() {.noconv.} =
        quit("exiting...", 1)

    setControlCHook(ctrlc)

    type Coords = object
        latitude: float
        longitude: float

    type FormattedWeather = object
        dateTime: seq[string]
        weather: seq[string]
        temperature: seq[string]
        feelsLike: seq[string]
        windSpeed: seq[string]
        humidity: seq[string]

    proc newFormattedWeather(): ref FormattedWeather =
        result = new FormattedWeather
        result.dateTime = newSeq[string]()
        result.weather = newSeq[string]()
        result.temperature = newSeq[string]()
        result.feelsLike = newSeq[string]()
        result.windSpeed = newSeq[string]()
        result.humidity = newSeq[string]()

    proc getGeoLocation(): Coords =
        if not locationPermissions:
            try:
                var permissions = readLineFromStdin("Do you allow 'weather' to get your location? [y/n]: ")

                while permissions != "y" and permissions != "n":
                    permissions = readLineFromStdin("Please enter a valid answer. [y/n]: ")

                if permissions != "y":
                    quit("Error: Can't get weather for your current location due to insufficient permissions.", 1)
            except IOError:
                quit("Error: Can't get weather for your current location due to insufficient permissions.", 1)

        try:
            var client = newHttpClient()
            let response: string = client.getContent("https://freegeoip.app/json/")
            let data: JsonNode = parseJson(response)
            var coords: Coords

            coords.latitude = data["latitude"].getFloat
            coords.longitude = data["longitude"].getFLoat

            coords
        except Exception:
            quit("Error: Unable to get your current location. Please make sure you're connected to the internet.\nIf this error persists, contact the developers.", 1)

    proc getWeatherLatLng(lat: float, lng: float, forecast: string): JsonNode =
        var res: JsonNode
        var client = newHttpClient()
        var weatherType = if (forecast == "now"): "weather" else: "forecast"
        var response: string
        try:
            response = client.getContent(fmt"https://api.openweathermap.org/data/2.5/{weatherType}?lat={lat}&lon={lng}&units=metric&appid={WEATHER_API_KEY}")
        except Exception:
            quit("Error: Unable to get weather for your current location. Please make sure you're connected to the internet.\nIf this error persists, contact the developers.", 1)
        client.close()
        res = parseJson(response)

        var weather: seq[JsonNode]
        case forecast:
            of "now":
                return res
            of "today":
                weather = res["list"].filterIt(
                    isToday(fromUnix(it["dt"].getInt()).utc))
            of "tomorrow":
                weather = res["list"].filterIt(
                    isTomorrow(fromUnix(it["dt"].getInt()).utc))
            of "week":
                weather = res["list"].filterIt(
                    isMidday(fromUnix(it["dt"].getInt()).utc))
        return %*{"city": res["city"], "weather": weather}

    proc getWeatherCity(location: string, forecast: string): JsonNode =
        var res: JsonNode
        var client = newHttpClient()
        var weatherType = if (forecast == "now"): "weather" else: "forecast"
        var response: string
        try:
            response = client.getContent(fmt"https://api.openweathermap.org/data/2.5/{weatherType}?q={location}&units=metric&appid={WEATHER_API_KEY}")
        except HttpRequestError:
            quit((fmt"Error: Location '{location}' not found. Please make sure you have the correct spelling."), 1)
        except Exception:
            quit((fmt"Error: Unable to get weather for '{location}'. Please make sure you're connected to the internet."&"\nIf this error persists, contact the developers."), 1)
        client.close()
        res = parseJson(response)

        var weather: seq[JsonNode]
        case forecast:
            of "now":
                return res
            of "today":
                weather = res["list"].filterIt(
                    isToday(fromUnix(it["dt"].getInt()).utc))
            of "tomorrow":
                weather = res["list"].filterIt(
                    isTomorrow(fromUnix(it["dt"].getInt()).utc))
            of "week":
                weather = res["list"].filterIt(
                    isMidday(fromUnix(it["dt"].getInt()).utc))
        return %*{"weather": weather}

    proc displayCurrentWeather(input: JsonNode) =
        let weather = input["weather"]
        let main = input["main"]
        let temp = main["temp"].getFloat()
        let feelsLike = main["feels_like"].getFloat()
        let tempMin = main["temp_min"].getFloat()
        let tempMax = main["temp_max"].getFloat()
        let humidity = $main["humidity"].getFloat()
        let windSpeed = $input["wind"]["speed"].getFloat()
        let tempColour = temp.getTemperatureColour
        let feelsLikeColour = feelsLike.getTemperatureColour
        let minColour = tempMin.getTemperatureColour
        let maxColour = tempMax.getTemperatureColour

        let table = newAsciiTable()
        table.addRow(@["Weather:", weather[0]["description"].getStr().fgWhite.bold])
        table.addRow(@["Temperature:", tempColour("●") & " " & tempColour(
                fmt"{round(temp)}°C")])
        table.addRow(@["Feels Like:", feels_likeColour("●") & " " &
                feels_likeColour(fmt"{round(feelsLike)}°C")])
        table.addRow(@["Min | Max:", minColour(fmt"{round(tempMin)}°C") &
                " | " & maxColour(fmt"{round(tempMax)}°C")])
        table.addRow(@["Wind Speed:", windSpeed.fgWhite.bold & "m/s"])
        table.addRow(@["Humidity:", humidity.fgWhite.bold & "%"])

        table.printTable(disableColour)

    proc formatWeather(input: JsonNode, table: ref AsciiTable,
            formatWeek: bool): ref AsciiTable =
        let weather = input["weather"]

        let weatherFormatted = newFormattedWeather()
        if formatWeek:
            weatherFormatted.dateTime.add("Date:")
        else:
            weatherFormatted.dateTime.add("Time:")
        weatherFormatted.weather.add("Weather:")
        weatherFormatted.temperature.add("Temperature:")
        weatherFormatted.feelsLike.add("Feels Like:")
        weatherFormatted.windSpeed.add("Wind Speed:")
        weatherFormatted.humidity.add("Humidity:")

        for d in weather:
            let temp = d["main"]["temp"].getFloat()
            let feelsLike = d["main"]["feels_like"].getFloat()
            let tempColour = temp.getTemperatureColour
            let feelsLikeColour = feelsLike.getTemperatureColour

            if formatWeek:
                weatherFormatted.dateTime.add(
                    (format(fromUnix(d["dt"].getInt()), "ddd dd MMM yyyy", utc())).fgWhite.bold)
            else:
                weatherFormatted.dateTime.add(
                    (format(fromUnix(d["dt"].getInt()), "h tt", utc())).fgWhite.bold)
            weatherFormatted.weather.add(
                d["weather"][0]["description"].getStr().fgWhite.bold)
            weatherFormatted.temperature.add(
                tempColour("●") & " " & tempColour(fmt"{round(temp)}°C"))
            weatherFormatted.feelsLike.add(
                feelsLikeColour("●") & " " &
                feelsLikeColour(fmt"{round(feelsLike)}°C"))
            weatherFormatted.windSpeed.add(
                ($d["wind"]["speed"].getFloat() & "m/s").fgWhite.bold)
            weatherFormatted.humidity.add(
                ($d["main"]["humidity"] & "%").fgWhite.bold)

        if not formatWeek:
            table.addRow(@["Date:",
                           format(
                                fromUnix(weather[0]["dt"].getInt()),
                                "ddd dd MMM yyyy",
                                utc()).fgWhite.bold
            ])
        table.addRow(weatherFormatted.dateTime)
        table.addRow(weatherFormatted.weather)
        table.addRow(weatherFormatted.temperature)
        table.addRow(weatherFormatted.feelsLike)
        table.addRow(weatherFormatted.windSpeed)
        table.addRow(weatherFormatted.humidity)

        return table

    proc displayMultiValueWeather(input: JsonNode, formatWeek: bool) =
        let weather = input["weather"]

        if weather.len == 0:
            if formatWeek:
                quit(fmt"Cannot get week weather for {locationCity}. Try using 'weather <city> tomorrow' or 'weather <city> now'.", 1)
            else:
                quit(fmt"Cannot get 3 hour weather for {locationCity}. Try using 'weather <city> tomorrow' or 'weather <city> now'.", 1)

        let table = formatWeather(input, newAsciiTable(), formatWeek)

        table.printTable(disableColour)

    proc getForecast(location: string, forecast: string) =
        var res: JsonNode
        var fcast = forecast
        if (match(location, re"^here|now|today|tomorrow|week$")):
            if location != "here":
                fcast = location
            let coords: Coords = getGeoLocation()
            res = getWeatherLatLng(coords.latitude, coords.longitude, fcast)
        else:
            locationCity = location
            res = getWeatherCity(location, fcast)

        if (fcast == "now"):
            displayCurrentWeather(res)
        else:
            displayMultiValueWeather(res, fcast == "week")

    proc main() =
        add_header("weather")
        add_header("2.0.0")
        add_header("Command line tool to get the weather forecast")
        add_example(title = "Usage", content = "weather [<location|forecast>] [<forecast>]")
        add_example(title = "Get weather for current location",
                content = "weather")
        add_example(title = "Get tomorrow's weather in london",
                content = "weather london tomorrow")
        add_example(title = "Get the weather for this week",
                content = "weather week")

        let location = use_arg(name = "location", kind = "argument",
                required = false, value = "here",
                help = "City name to get weather forecast. Use 'here' to get weather for current location. Enclose city names with spaces in \"\"")
        let forecast = use_arg(name = "forecast", kind = "argument",
                required = false, value = "now",
                help = "Type of weather forecast to get. Options are: [now, today, tomorrow, week]")
        let version = use_arg(name = "version", kind = "flag", required = false,
                help = "Display version", alt = "v")
        let allowPerms = use_arg(name = "allow", kind = "flag",
                required = false, help = "Allow location permissions", alt = "y")
        let help = use_arg(name = "help", kind = "flag", required = false,
                help = "Display help", alt = "h")
        let noColour = use_arg(name = "no-colour", kind = "flag",
                required = false, help = "Disable colour output")

        parse_args()

        if version.used:
            print_header()
            quit(0)
        if not match(forecast.value, re"^now|today|tomorrow|week$"):
            quit("Error: Invalid value for forecast", 1)
        if allowPerms.used:
            locationPermissions = true
        if help.used:
            print_help()
            quit(0)
        disableColour = noColour.used
        if detectOs(Windows):
            disableColour = true

        getForecast(location.value, forecast.value)

    main()
