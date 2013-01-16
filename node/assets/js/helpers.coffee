@map = (value, fromMin, fromMax, toMin, toMax) ->
  norm = undefined
  value = parseInt(value)
  fromMin = parseInt(fromMin)
  fromMax = parseInt(fromMax)
  toMin = parseInt(toMin)
  toMax = parseInt(toMax)
  norm = (value - fromMin) / (fromMax - fromMin).toFixed(1)
  norm * (toMax - toMin) + toMin

