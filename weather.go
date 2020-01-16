package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"regexp"

	"github.com/docopt/docopt-go"
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

type CurrentWeather struct {
	Weather []struct {
		Description string `json:"description"`
	} `json:"weather"`
	Main struct {
		Temp      float64 `json:"temp"`
		FeelsLike float64 `json:"feels_like"`
		TempMin   int     `json:"temp_min"`
		TempMax   int     `json:"temp_max"`
		Humidity  int     `json:"humidity"`
	} `json:"main"`
	Wind struct {
		Speed float64 `json:"speed"`
	} `json:"wind"`
	Name string `json:"name"`
}

type DayWeather struct {
	List []struct {
		Main struct {
			Temp      int     `json:"temp"`
			FeelsLike float64 `json:"feels_like"`
			Humidity  int     `json:"humidity"`
		} `json:"main"`
		Weather []struct {
			Description string `json:"description"`
		} `json:"weather"`
		Wind struct {
			Speed float64 `json:"speed"`
		} `json:"wind"`
		DtTxt string `json:"dt_txt"`
	} `json:"list"`
	City struct {
		Name string `json:"name"`
	} `json:"city"`
}

func printError(errorMessage string) {
	e := color.New(color.FgRed, color.Bold)
	e.Println(errorMessage)
	os.Exit(1)
}

func getCoords() (string, string) {
	res, err := http.Get("http://freegeoip.app/json/")
	if err != nil {
		printError("There was an error getting your location. Please make sure you're connected to the internet")
	}
	defer res.Body.Close()
	body, err := ioutil.ReadAll(res.Body)
	if err != nil {
		log.Fatal(err)
	}
	results := gjson.GetMany(string(body), "latitude", "longitude")
	return results[0].String(), results[1].String()
}

func getWeatherLatLng(lat string, lng string, forecast string) string {
	WEATHER_API_KEY := os.Getenv("WEATHER_API_KEY")
	var format string
	if forecast == "now" {
		format = "weather"
	} else {
		format = "forecast"
	}
	res, err := http.Get(fmt.Sprintf("http://api.openweathermap.org/data/2.5/%s?lat=%s&lon=%s&units=metric&appid=%s", format, lat, lng, WEATHER_API_KEY))
	if err != nil {
		printError("There was an error getting the weather for your current location. Make sure you're connected to the Internet.\nContact the developers if the issue persists.")
	}
	defer res.Body.Close()
	body, err := ioutil.ReadAll(res.Body)
	if err != nil {
		printError("There was an error getting the weather for your current location. Make sure you're connected to the Internet.\nContact the developers if the issue persists.")
	}
	m, ok := gjson.Parse(string(body)).Value().(map[string]interface{})
	return m
}

func getWeatherCity(location string, forecast string) {
	// WEATHER_API_KEY := os.Getenv("WEATHER_API_KEY")
}

func getTemperatureColour(temp float32) *color.Color {
	if temp < 0 {
		return color.New(color.FgBlue, color.Bold)
	} else if temp < 5 {
		return color.New(color.FgHiBlue, color.Bold)
	} else if temp < 10 {
		return color.New(color.FgCyan, color.Bold)
	} else if temp < 15 {
		return color.New(color.FgHiCyan, color.Bold)
	} else if temp < 20 {
		return color.New(color.FgGreen, color.Bold)
	} else if temp < 25 {
		return color.New(color.FgHiGreen, color.Bold)
	} else if temp < 30 {
		return color.New(color.FgYellow, color.Bold)
	} else if temp < 35 {
		return color.New(color.FgHiYellow, color.Bold)
	} else if temp < 40 {
		return color.New(color.FgRed, color.Bold)
	} else {
		return color.New(color.FgWhite, color.Bold)
	}
}

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
		println(getWeatherLatLng(lat, lng, forecast))
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

	getForecast(location, forecast)
}
