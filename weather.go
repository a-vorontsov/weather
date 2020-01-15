package main

import (
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"regexp"

	docopt "github.com/docopt/docopt-go"
	"github.com/fatih/color"
	"github.com/tidwall/gjson"

	_ "github.com/joho/godotenv/autoload"
)

const usage = `weather
Version: 2.0.0

Usage:
  weather [LOCATION] [FORECAST]

Arguments:
  LOCATION		City name to get weather forecast. Use 'here' to get weather for current location. Enclose city names with spaces in "". [default: "here"]
  FORECAST		Type of forecast to get. Options are: now, today, tomorrow, week. [default: "now"]

Options:
  -h --help     Show this screen.
  --no-colour   Disable colour output.`

func printError(errorMessage string) {
	e := color.New(color.FgRed, color.Bold)
	e.Println(errorMessage)
	os.Exit(1)
}

func getCoords() (float64, float64) {
	resp, err := http.Get("http://freegeoip.app/json/")
	if err != nil {
		printError("There was an error getting your location. Please make sure you're connected to the internet")
	}
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	results := gjson.GetMany(string(body), "latitude", "longitude")
	return results[0].Float(), results[1].Float()
}

func getWeatherLatLng(lat float64, lng float64, forecast string) {
	// WEATHER_API_KEY := os.Getenv("WEATHER_API_KEY")
}

func getWeatherCity(location string, forecast string) {
	// WEATHER_API_KEY := os.Getenv("WEATHER_API_KEY")
}

func getTemperatureColour() {}

func displayCurrentWeather() {}

func formatDayWeather() {}

func formatWeekWeather() {}

func displayMultiValueWeather(valueType string) {}

func getForecast(location string, forecast string) {
	if regexp.MustCompile("^here|now|today|tomorrow|week$").Match([]byte(location)) {
		lat, lng := getCoords()
		if location != "here" {
			forecast = location
		}
		getWeatherLatLng(lat, lng, forecast)
	} else {
		getWeatherCity(location, forecast)
	}
	if forecast == "now" {
		displayCurrentWeather()
	} else {
		var valueType string
		if forecast == "week" {
			valueType = "daily"
		} else {
			valueType = "hourly"
		}
		displayMultiValueWeather(valueType)
	}
}

func main() {
	arguments, _ := docopt.ParseDoc(usage)

	var location string
	var forecast string
	if arguments["LOCATION"] != nil {
		location = arguments["LOCATION"].(string)
	} else {
		location = "here"
	}
	if arguments["FORECAST"] != nil {
		forecast = arguments["FORECAST"].(string)
	} else {
		forecast = "now"
	}

	if !regexp.MustCompile("^now|today|tomorrow|week$").Match([]byte(forecast)) {
		printError(fmt.Sprintf("Error: Invalid value %s for argument 'forecast'", forecast))
	}

	println(location)
	println(forecast)

	lat, lng := getCoords()
	println(lat)
	println(lng)
}
