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
  # set up the socket.io and OSC
  socket = io.connect() 

  socket.on "connection", (msg) ->
    socket.emit "pageId", a.pageId
    socket.emit "getContent", a.pageId

  socket.on "activate", (msg) ->
    $("#level1").fadeIn()
    $(".level2").fadeOut()
    $("#home").fadeOut 400
    #$('#content').show()

  socket.on "deactivate", (msg) ->
    $("#home").fadeIn 400
    $("#level1").fadeIn()
    $(".level2").fadeOut()
    #$('#content').hide()

  socket.on "content", (content) ->
    for i, json of content
      if "#{i}" != "main"
        console.log i
        level2 = $("<div class='level2 #{i}'></div>")
        for j, level1 of json
          #console.log "#{j} -> "
          div = $(_.template($('#square-template').html(), level1))
          $(level2).append(div)
        $('#main').append level2

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


  $('.level1').click () ->
    me = @
    $('#level1').fadeOut 400, () ->
      $(".level2.#{$(me).data('sub')}").fadeIn 400


