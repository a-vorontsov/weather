# Package

version       = "2.0.0"
author        = "Aleksandr Vorontsov"
description   = "Command line tool to get the weather forecast"
license       = "ISC"
srcDir        = "src"
bin           = @["weather"]
skipExt       = @["nim"]


# Dependencies
requires "nim >= 1.0.4"
requires "dotenv >= 1.1.1"
requires "nap >= 1.5.1"
requires "colorize >= 0.2.0"
