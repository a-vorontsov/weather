import times, colorize

proc isToday*(date: DateTime): bool =
  return date.yearday == now().yearday

proc isTomorrow*(date: DateTime): bool =
  return date.yearday == (now() + 1.days).yearday

proc isMidDay*(date: DateTime): bool =
  return date.hour == 12

proc getTemperatureColour*(temp: float): (proc(s: string): string) =
  if (temp < 0):
    return proc(val: string): string = val.fgBlue.bold
  elif (temp < 5):
    return proc(val: string): string = val.fgLightBlue.bold
  elif(temp < 10):
    return proc(val: string): string = val.fgCyan.bold
  elif(temp < 15):
    return proc(val: string): string = val.fgLightCyan.bold
  elif(temp < 20):
    return proc(val: string): string = val.fgGreen.bold
  elif(temp < 25):
    return proc(val: string): string = val.fgLightGreen.bold
  elif(temp < 30):
    return proc(val: string): string = val.fgYellow.bold
  elif(temp < 35):
    return proc(val: string): string = val.fgLightYellow.bold
  elif(temp < 40):
    return proc(val: string): string = val.fgRed.bold
  else:
    return proc(val: string): string = val.fgWhite.bold
