#= require jquery
#= require jquery.validate
#= require underscore
# =require backbone
#= require bootstrapManifest
#= require baseClasses
# =require socket.io
# =require osc.io
# =require helpers
# =require models/entry
# =require collections/entries
# =require views/gallery

@a = @a || {}

@a.entries = {}

$(window).ready ->
  $('#main').css 'background-image', "url(/img/gallery/IMG_#{a.pageId}.JPG)"
  # set up the socket.io and OSC
  socket = io.connect "http://localhost" 

  socket.on "connection", (msg) ->
    $("#main").append("<h2>#{msg}</h2>")
    socket.emit "pageId", a.pageId

  #osc_client = new OscClient {
    #host: "127.0.0.1"
    #port: 7654
  #}
  #osc_server = new OscServer {
    #host: "127.0.0.1"
    #port: 7655
  #}

  #osc_server.on "osc",  (msg)  ->
    #data = JSON.parse msg.path 
    #a.user.updatePosition data  if data.hands
    #a.user.set({'status': data.user })  if data.user



