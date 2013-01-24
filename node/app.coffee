###
Module dependencies.
###
config = require("./config")
express = require("express")
path = require("path")
http = require("http")
socketIo = require("socket.io")
osc = require("osc.io")
mongoose = require("mongoose")
MongoStore = require("connect-mongo")(express)
sessionStore = new MongoStore(url: config.mongodb)
fs = require("fs")

# connect the database
mongoose.connect config.mongodb

# create app, server, and web sockets
app = express()
server = http.createServer(app)
io = socketIo.listen(server)

# Make socket.io a little quieter
io.set "log level", 1

# Give socket.io access to the passport user from Express
#io.set('authorization', passportSocketIo.authorize(
  #sessionKey: 'connect.sid',
  #sessionStore: sessionStore,
  #sessionSecret: config.sessionSecret,
  #fail: (data, accept) ->
  #keeps socket.io from bombing when user isn't logged in
    #accept(null, true);
#));
app.configure ->
  app.set "port", process.env.PORT or 3000
  app.set "views", __dirname + "/views"
  app.set "view engine", "jade"
  
  # use the connect assets middleware for Snockets sugar
  app.use require("connect-assets")()
  app.use express.favicon()
  app.use express.logger(config.loggerFormat)
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.cookieParser(config.sessionSecret)
  app.use express.session(store: sessionStore)
  app.use app.router
  app.use require("less-middleware")(src: __dirname + "/public")
  app.use express.static(path.join(__dirname, "public"))
  app.use osc(io,
    log: false
  )
  
  app.use(osc(io));
  app.use express.errorHandler()  if config.useErrorHandler

entries = {}

activePages = {}
socketMap = {}
content = {}
heroes = {}
buckets = {}
controller = null
tvSocket = null

basePath = "./public/img/gallery/"
urlBase = "/img/gallery/"

doFirstLevel = (first, next) ->
  content[first] = {}
  fs.readdir "#{basePath}#{first}", (err, secondLevel) ->
    secondLevel = secondLevel.toString().replace(".DS_Store,","").split(',')
    for second in secondLevel
      console.log("second: #{second}")
      doSecondLevel(first, second, (i) ->
        if "#{i}" == "#{( secondLevel.length - 2 )}"
          next(first)
      )

doSecondLevel = (first, second, next) ->
  content[first][second] = {}
  fs.readdir "#{basePath}#{first}/#{second}", (err, files) ->
    files = files.toString().replace(".DS_Store,","").split(',')
    count = 0
    console.log "files #{files.length}"
    for file in files
      doFileLevel(first, second, file.toLowerCase(), count++, (i) ->
        if "#{i}" == "#{( files.length - 1 )}"
          next(second)
      )

doFileLevel = (first, second, file, count, next) ->
  content[first][second] = content[first][second] || {}
  #console.log "file #{file}"
  if file.match(".txt")
    fs.readFile "#{basePath}#{first}/#{second}/#{file}", (err, lines) ->
      #console.log "text file: #{lines}"
      file = file.replace(".txt","")
      content[first][second][file] = content[first][second][file] || {}
      content[first][second][file].text = "#{lines}"
      next(count)
  else if file.match(".jpg") || file.match(".png")
    name = file.replace(".jpg","").replace(".png","")
    content[first][second][name] = content[first][second][name] || {}
    #console.log "first: #{first}, second #{second}, file #{name}"
    content[first][second][name].img = "#{urlBase}#{first}/#{second}/#{file}"
    next(count)

getContent = (next) ->
  fs.readdir "#{basePath}", (err, firstLevel) ->
    firstLevel = firstLevel.toString().replace(".DS_Store,","").split(',')
    for first in firstLevel
      console.log "first #{first}"
      doFirstLevel(first, (i) ->
        console.log "return doFrist #{i}"
        if firstLevel.indexOf(i) == ( firstLevel.length - 1 )
          #console.log "done with first"
          next()
      )

getContent ->
  #console.log "cotent #{JSON.stringify(content)}"
  count = Object.keys socketMap
  for i in count
    socketMap[i]?.emit "content", "#{JSON.stringify(content)}"

io.sockets.on "connection",  (socket) ->
  socket.on "pageId", (msg) ->
    if "#{msg}" == "#{-1}"
      tvSocket = socket
      tvSocket?.emit "active", -1
    else
      activePages[msg] = socket.id
      socketMap[socket.id] = socket
      controller?.emit "activePages", activePages

    socket.emit "content", content[msg]

    console.log socket.id

  socket.emit "connection", "I am your father"

  socket.on "disconnect", ->
    delete activePages[socket.id]
    controller?.emit "activePages", activePages

  socket.on "getPages", () ->
    console.log "sending pages"
    controller = socket
    controller?.emit "activePages", activePages

  socket.on "getContent", () ->
    console.log "youlll get it"
    #socket?.emit "content", JSON.stringify(content)

  socket.on "heroes", (data) ->
    heroes[data.id] = data.heroes

  socket.on "buckets", (data) ->
    buckets[data.id] = data.buckets
    tvSocket?.emit "buckets", buckets

  socket.on "getBuckets", () ->
    tvSocket?.emit "buckets", buckets

  socket.on "getHeroes", () ->
    tvSocket?.emit "heroes", heroes

  socket.on "hero", (data) ->
    tvSocket?.emit "hero", data

  socket.on "clickedPage", (id) ->
    console.log activePages[id]
    activatePage id

  socket.on "click", (data) ->
    tvSocket?.emit "clicked", data

  socket.on "scroll", (data) ->
    tvSocket?.emit "scrolled", data


  activatePage = (id) ->
    socketMap[id]?.emit "activate", "foo"
    tvSocket?.emit "active", id
    socket
    count = Object.keys socketMap
    for i in count
      if i != id
        socketMap[i]?.emit "deactivate", "foo"

  # this flips the socket from active, then back to deactive
  delayActivateFlip = (soc, time, c, speed) ->
    speed = speed || 500
    setTimeout ->
      soc?.emit "activate", "foo"
    , speed * c
    setTimeout ->
      soc?.emit "deactivate", "foo"
    , speed * ( c + 1 )

  # this does a cycle of all screens calling delayActiveFlip
  doCycle = (time, speed) ->
    setTimeout ->
      console.log "cycle: #{time}"
      c = 0
      length = Object.keys socketMap
      for i in length
        delayActivateFlip socketMap[i], time, c++, speed
    , speed * time

  # cycle through as many times as we need to
  socket.on "cycle", (times) ->
    times = times || 2
    length = Object.keys socketMap
    for i in length
      socketMap[i]?.emit "deactivate", "foo"
    time = 0
    speed = 500
    while time < times
      doCycle(time++, speed)



# UI routes
app.get "/", (req, res) ->
  res.render "index.jade",
    title: "Media Event"

app.get "/controller", (req, res) ->
  res.render "controller.jade",
    title: "Media Event"

app.get "/tv", (req, res) ->
  res.render "tv.jade",
    title: "Media Event"
    pageId: -1

app.get "/:id", (req, res) ->
  res.render "page.jade",
    title: "Media Event"
    pageId: req.params.id

server.listen app.get("port"), ->
  console.log "Express server listening on port " + app.get("port")

