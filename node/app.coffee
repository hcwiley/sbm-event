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
controller = null

io.sockets.on "connection",  (socket) ->
  socket.on "pageId", (msg) ->
    activePages[socket.id] = msg
    socketMap[socket.id] = socket
    controller?.emit "activePages", activePages
    console.log socket.id

  socket.emit "connection", "I am your father"

  socket.on "disconnect", ->
    delete activePages[socket.id]
    controller?.emit "activePages", activePages

  socket.on "getPages", () ->
    console.log "sending pages"
    controller = socket
    controller?.emit "activePages", activePages

  socket.on "clickedPage", (id) ->
    console.log activePages[id]
    socketMap[id].emit "activate", "foo"
    count = Object.keys socketMap
    for i in count
      if i != id
        socketMap[i].emit "deactivate", "foo"

  socket.on "cycle", () ->
    console.log "cycle"
    length = Object.keys socketMap
    c = 0
    for i in length
      setTimeout ->
        socketMap[i].emit "activate", "foo"
        setTimeout ->
          socketMap[i].emit "deactivate", "foo"
        , 500 * c
      , 500 * c++



# UI routes
app.get "/", (req, res) ->
  res.render "index.jade",
    title: "Media Event"

app.get "/controller", (req, res) ->
  res.render "controller.jade",
    title: "Media Event"

app.get "/:id", (req, res) ->
  res.render "index.jade",
    title: "Media Event"
    pageId: req.params.id

server.listen app.get("port"), ->
  console.log "Express server listening on port " + app.get("port")

