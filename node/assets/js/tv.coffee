#= require jquery
#= require underscore
# =require backbone
#= require bootstrapManifest
# =require socket.io
# =require helpers

@a = @a || {}

@a.entries = {}

$(window).ready ->
  # set up the socket.io and OSC
  socket = io.connect() 

  socket.on "connection", (msg) ->
    socket.emit "pageId", a.pageId

  socket.on "active", (id) ->
    console.log "active: #{id}"

  socket.on "clicked", (div) ->
    if div == "#home"
      console.log "home home on tha range"

  socket.on "hero", (div) ->
    console.log "hero #{div}"
    div = $(_.template($('#hero-template').html(), div))
    $("#home").html div

  socket.on "content", (content) ->
    for i, json of content
      console.log i
      if "#{i}" == "bucket"
        doBucket json, i
      else
        for j, level1 of json
          div = $(_.template($('#hero-template').html(), level1))
          $(div).addClass("hidden")
          $("#home").append(div)

  doBucket = (json, i) ->
    for j, level1 of json
      #console.log "#{j} -> "
      div = $(_.template($('#square-template').html(), level1))
      $('#level1').append(div)
      aTime = 400
      $(div).attr "id", "#{i}-#{j}"
      $(div).click ->
        me = @
        if a.open
          a.open = false
          $(me).animate {
            left: $(me).data("x0"),
            top: $(me).data("y0"),
            width: $(me).data("w0"),
            height: $(me).data("h0"),
            "z-index": 1,
          }, aTime, ->
            if $(me).data "tall"
              $(me).children("img").css "width", "auto"
              $(me).children("img").css "height", "100%"
            else
              $(me).children("img").css "width", "100%"
              $(me).children("img").css "height", "auto"
            $(me).css "overflow", "hidden"
          #setTimeout ->
            #$('.level1').fadeIn(aTime)
          #, aTime

        else
          a.open = true
          #$('.level1').not(me).hide()
          $(me).css "z-index", 100
          #$('#level1').animate {
            #scrollTop: 0+"px"
          #}, 300, ->
          $(me).animate {
            top: $('#level1').scrollTop(),
            left: 0,
            width: $(window).width(),
            height: $(window).height(),
          }, 400
          $(me).children('img').width($(window).width())
          $(me).children('img').height($(window).height())
