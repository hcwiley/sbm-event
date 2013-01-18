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
          spacingX = 310
          spacingY = 310
          y0 = 0
          x0 = 0
          $(div).attr "id", "#{i}-#{j}"
          $(div).css "top", ( spacingY *  parseInt( j / 3 ) ) + y0
          $(div).css "left", ( spacingX * ( j % 3 )) + x0
          aTime = 400
          $(div).click ->
            if $(@).data "open"
              $(@).data "open", false
              $(@).animate {
                left: $(@).data("x0"),
                top: $(@).data("y0"),
                width: $(@).data("w0"),
                height: $(@).data("h0")
              }, aTime
              setTimeout ->
                $('.square').fadeIn(aTime)
              , aTime / 4

            else
              $(@).data "open", true
              $('.square').not(@).hide()
              $(@).data "w0", $(@).width()
              $(@).data "h0", $(@).height()
              $(@).data "x0", $(@).css "left"
              $(@).data "y0", $(@).css "top"
              toLeft = 0 - $(@).data "x0"
              toTop = 0 - $(@).data "y0"
              $(@).animate {
                top: 0,
                left: 0,
                width: $(window).width() * .85,
                height: $(window).height() * .85
              }, 400
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


