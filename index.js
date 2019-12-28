#!/usr/bin/env node
const path = require("path");
const dotenvAbsolutePath = path.join(__dirname, '.env');

const dotenv = require('dotenv').config({
    path: dotenvAbsolutePath
});
if (dotenv.error) {
    throw dotenv.error;
}
const program = require("caporal");
const request = require("superagent");
const isToday = require("date-fns/isToday");
const isTomorrow = require("date-fns/isTomorrow");
const dateFormat = require("date-fns/format");
const chalk = require("chalk");
const Table = require("cli-table3");

const getPublicIp = async () => {
    const publicIp = require("public-ip");
    const ip = await publicIp.v4();

    return ip;
}

const getLocalLatLng = async () => {
    const geoIp = require("geoip-lite");

    const ip = await getPublicIp();
    const ll = geoIp.lookup(ip).ll;

    return {
        lat: ll[0],
        lng: ll[1]
    };
}

const getCurrentWeatherLatLng = async (lat, lng) => {
    const res = await request.get(`http://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lng}&units=metric&appid=${process.env.WEATHER_API_KEY}`);
    return res.body;
}

const getTodayWeatherLatLng = async (lat, lng) => {
    const res = await request.get(`http://api.openweathermap.org/data/2.5/forecast?lat=${lat}&lon=${lng}&units=metric&appid=${process.env.WEATHER_API_KEY}`);
    const weather = res.body.list.filter(i => isToday(new Date(i.dt_txt)));
    return {city: res.body.city, weather};
}

const getTomorrowWeatherLatLng = async (lat, lng) => {
    const res = await request.get(`http://api.openweathermap.org/data/2.5/forecast?lat=${lat}&lon=${lng}&units=metric&appid=${process.env.WEATHER_API_KEY}`);
    const weather = res.body.list.filter(i => isTomorrow(new Date(i.dt_txt)));
    return {city: res.body.city, weather};
}

const getWeekWeatherLatLng = async (lat, lng) => {
    const res = await request.get(`http://api.openweathermap.org/data/2.5/forecast?lat=${lat}&lon=${lng}&units=metric&appid=${process.env.WEATHER_API_KEY}`);
    const weather = res.body.list.filter(i => new Date(i.dt_txt).getHours() === 12);
    return {city: res.body.city, weather};
}

const getCurrentWeatherCity = async (city) => {
    const res = await request.get(`http://api.openweathermap.org/data/2.5/weather?q=${city}&units=metric&appid=${process.env.WEATHER_API_KEY}`);
    return res.body;
}

const getTodayWeatherCity = async (city) => {
    const res = await request.get(`http://api.openweathermap.org/data/2.5/forecast?q=${city}&units=metric&appid=${process.env.WEATHER_API_KEY}`);
    const weather = res.body.list.filter(i => isToday(new Date(i.dt_txt)));
    return {city: res.body.city, weather};
}

const getTomorrowWeatherCity = async (city) => {
    const res = await request.get(`http://api.openweathermap.org/data/2.5/forecast?q=${city}&units=metric&appid=${process.env.WEATHER_API_KEY}`);
    const weather = res.body.list.filter(i => isTomorrow(new Date(i.dt_txt)));
    return {city: res.body.city, weather};
}

const getWeekWeatherCity = async (city) => {
    const res = await request.get(`http://api.openweathermap.org/data/2.5/forecast?q=${city}&units=metric&appid=${process.env.WEATHER_API_KEY}`);
    const weather = res.body.list.filter(i => new Date(i.dt_txt).getHours() === 12);
    return {city: res.body.city, weather};
}

const getTemperatureColour = (temp) => {
    if (temp < 0) {
        return chalk.blue.bold;
    } else if (temp >= 0 && temp < 5) {
        return chalk.blueBright.bold;
    } else if (temp >= 5 && temp < 10) {
        return chalk.cyan.bold;
    } else if (temp >= 10 && temp < 15) {
        return chalk.cyanBright.bold;
    } else if (temp >= 15 && temp < 20) {
        return chalk.green.bold;
    } else if (temp >= 20 && temp < 25) {
        return chalk.greenBright.bold;
    } else if (temp >= 25 && temp < 30) {
        return chalk.yellow.bold;
    } else if (temp >= 30 && temp < 35) {
        return chalk.yellowBright.bold;
    } else if (temp >= 30 && temp < 40) {
        return chalk.red.bold;
    } else {
        return chalk.white.bold;
    }
}

const displayCurrentWeather = (input) => {
    const {weather, main} = input;
    const {temp, feels_like, temp_min, temp_max, humidity} = main;
    const tempColour = getTemperatureColour(temp);
    const feels_likeColour = getTemperatureColour(feels_like);
    const minColour = getTemperatureColour(temp_min);
    const maxColour = getTemperatureColour(temp_max);

    const table = new Table({
        colWidths: [16],
        style: {
            border:[],
            head:[],
            "padding-left": 0,
            "padding-right": 2
        },
        chars: {
            "top": "",
            "top-mid": "",
            "top-left": "",
            "top-right": "",
            "bottom": "",
            "bottom-mid": "",
            "bottom-left": "",
            "bottom-right": "",
            "left": "",
            "left-mid": "",
            "mid": "",
            "mid-mid": "",
            "right": "",
            "right-mid": "",
            "middle": ""
        }
    });

    table.push(
        {"Location:": chalk.whiteBright.bold(input.name)},
        {"Weather:": chalk.whiteBright.bold(weather[0].description)},
        {"Temperature:": `${tempColour("●")} ${tempColour(Math.round(temp)+"°C")}`},
        {"Feels Like:": `${feels_likeColour("●")} ${feels_likeColour(Math.round(feels_like)+"°C")}`},
        {"Min | Max:": `${minColour(Math.round(temp_min)+"°C")} | ${maxColour(Math.round(temp_max)+"°C")}`},
        {"Wind Speed:": chalk.whiteBright.bold(input.wind.speed+"m/s")},
        {"Humidity:": chalk.whiteBright.bold(humidity+"%")}
    );

    console.log(table.toString());
}

const displayDayWeather = (input) => {
    const {weather, city} = input;

    if (weather.length === 0) {
        console.log(chalk.redBright.bold(`Cannot get 3 hour weather for ${city.name}. Try using 'weather <city> tomorrow' or 'weather <city> now'.`));
        return;
    }

    const table = new Table({
        colWidths: [16],
        style: {
            border:[],
            head:[],
            "padding-left": 0,
            "padding-right": 2
        },
        chars: {
            "top": "",
            "top-mid": "",
            "top-left": "",
            "top-right": "",
            "bottom": "",
            "bottom-mid": "",
            "bottom-left": "",
            "bottom-right": "",
            "left": "",
            "left-mid": "",
            "mid": "",
            "mid-mid": "",
            "right": "",
            "right-mid": "",
            "middle": ""
        }
    });

    const weatherFormatted = {
        time: [],
        weather: [],
        temperature: [],
        feels_like: [],
        wind_speed: [],
        humidity: [],
    };

    weather.forEach(d => {
        const tempColour = getTemperatureColour(d.main.temp);
        const feels_likeColour = getTemperatureColour(d.main.feels_like);

        weatherFormatted.time.push(chalk.whiteBright.bold(dateFormat(new Date(d.dt_txt), "h bbbb")));
        weatherFormatted.weather.push(chalk.whiteBright.bold(d.weather[0].description));
        weatherFormatted.temperature.push(`${tempColour("●")} ${tempColour(Math.round(d.main.temp)+"°C")}`);
        weatherFormatted.feels_like.push(`${feels_likeColour("●")} ${feels_likeColour(Math.round(d.main.feels_like)+"°C")}`);
        weatherFormatted.wind_speed.push(`${chalk.whiteBright.bold(d.wind.speed+"m/s")}`);
        weatherFormatted.humidity.push(`${chalk.whiteBright.bold(d.main.humidity+"%")}`);
    });

    table.push(
        {"Location:": {colSpan: weather.length, content: chalk.whiteBright.bold(city.name)}},
        {"Date:": {colSpan: weather.length, content: chalk.whiteBright.bold(dateFormat(new Date(weather[0].dt_txt), "eee do MMM y"))}},
        {"Time:": weatherFormatted.time},
        {"Weather:": weatherFormatted.weather},
        {"Temperature:": weatherFormatted.temperature},
        {"Feels Like:": weatherFormatted.feels_like},
        {"Wind Speed:": weatherFormatted.wind_speed},
        {"Humidity:": weatherFormatted.humidity}
    );

    console.log(table.toString());
}

const displayWeekWeather = (input) => {
    const {weather, city} = input;

    if (weather.length === 0) {
        console.log(chalk.redBright.bold(`Cannot get week weather for ${city.name}. Try using 'weather <city> now|today|tomorrow'.`));
        return;
    }

    const table = new Table({
        colWidths: [16],
        style: {
            border:[],
            head:[],
            "padding-left": 0,
            "padding-right": 2
        },
        chars: {
            "top": "",
            "top-mid": "",
            "top-left": "",
            "top-right": "",
            "bottom": "",
            "bottom-mid": "",
            "bottom-left": "",
            "bottom-right": "",
            "left": "",
            "left-mid": "",
            "mid": "",
            "mid-mid": "",
            "right": "",
            "right-mid": "",
            "middle": ""
        }
    });

    const weatherFormatted = {
        date: [],
        weather: [],
        temperature: [],
        feels_like: [],
        wind_speed: [],
        humidity: [],
    };

    weather.forEach(d => {
        const tempColour = getTemperatureColour(d.main.temp);
        const feels_likeColour = getTemperatureColour(d.main.feels_like);

        weatherFormatted.date.push(chalk.whiteBright.bold(dateFormat(new Date(d.dt_txt), "eee do MMM y")));
        weatherFormatted.weather.push(chalk.whiteBright.bold(d.weather[0].description));
        weatherFormatted.temperature.push(`${tempColour("●")} ${tempColour(Math.round(d.main.temp)+"°C")}`);
        weatherFormatted.feels_like.push(`${feels_likeColour("●")} ${feels_likeColour(Math.round(d.main.feels_like)+"°C")}`);
        weatherFormatted.wind_speed.push(`${chalk.whiteBright.bold(d.wind.speed+"m/s")}`);
        weatherFormatted.humidity.push(`${chalk.whiteBright.bold(d.main.humidity+"%")}`);
    });

    table.push(
        {"Location:": {colSpan: weather.length, content: chalk.whiteBright.bold(city.name)}},
        {"Date:": weatherFormatted.date},
        {"Weather:": weatherFormatted.weather},
        {"Temperature:": weatherFormatted.temperature},
        {"Feels Like:": weatherFormatted.feels_like},
        {"Wind Speed:": weatherFormatted.wind_speed},
        {"Humidity:": weatherFormatted.humidity}
    );

    console.log(table.toString());
}

const getForecast = async (logger, location, forecast) => {
    if (location === "here") {
        try {
            const {lat, lng} = await getLocalLatLng();
            let res;
            switch (forecast) {
                case "now":
                    res = await getCurrentWeatherLatLng(lat, lng);
                    displayCurrentWeather(res);
                    break;
                case "today":
                    res = await getTodayWeatherLatLng(lat, lng);
                    displayDayWeather(res);
                    break;
                case "tomorrow":
                    res = await getTomorrowWeatherLatLng(lat, lng);
                    displayDayWeather(res);
                    break;
                case "week":
                    res = await getWeekWeatherLatLng(lat, lng);
                    displayWeekWeather(res);
                    break;
            }
        } catch (err) {
            logger.error(err);
            process.exit(1);
        }
    } else if (/^now|today|tomorrow|week$/.test(location)) {
        try {
            const {lat, lng} = await getLocalLatLng();
            let res;
            forecast = location;
            switch (forecast) {
                case "now":
                    res = await getCurrentWeatherLatLng(lat, lng);
                    displayCurrentWeather(res);
                    break;
                case "today":
                    res = await getTodayWeatherLatLng(lat, lng);
                    displayDayWeather(res);
                    break;
                case "tomorrow":
                    res = await getTomorrowWeatherLatLng(lat, lng);
                    displayDayWeather(res);
                    break;
                case "week":
                    res = await getWeekWeatherLatLng(lat, lng);
                    displayWeekWeather(res);
                    break;
            }
        } catch (err) {
            logger.error(err);
            process.exit(1);
        }
    } else {
        try {
            let res;
            switch (forecast) {
                case "now":
                    res = await getCurrentWeatherCity(location);
                    displayCurrentWeather(res);
                    break;
                case "today":
                    res = await getTodayWeatherCity(location);
                    displayDayWeather(res);
                    break;
                case "tomorrow":
                    res = await getTomorrowWeatherCity(location);
                    displayDayWeather(res);
                    break;
                case "week":
                    res = await getWeekWeatherCity(location);
                    displayWeekWeather(res);
                    break;
            }
        } catch (err) {
            logger.error(err);
            process.exit(1);
        }
    }
}

program
    .name("weather")
    .version("1.0.0")
    .bin("weather")
    .description("Command line tool to get the weather forecast")
    .argument("[location]", "City name to get weather forecast. Use 'here' to get weather for current location. Enclose city names with spaces in \"\"", program.STRING, "here")
    .argument("[forecast type]", "Type of weather to get. Options are: [now, today, tomorrow, week]", /^now|today|tomorrow|week$/, "now")
    .action(async (args, _, logger) => {
        await getForecast(logger, args.location.toLowerCase(), args.forecastType.toLowerCase());
    });

program.parse(process.argv);
