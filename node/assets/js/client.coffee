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

Array.prototype.remove = (from, to) ->
  rest = @.slice((to || from) + 1 || @.length)
  if from < 0
    @.length = @.length + from
  else
    @.length = from
  return @.push.apply(@, rest)

$(window).ready ->
  # set up the socket.io and OSC
  socket = io.connect() 

  socket.on "connection", (msg) ->
    socket.emit "pageId", a.pageId
    socket.emit "getContent", a.pageId

  socket.on "activate", (msg) ->
    $("#level1").fadeIn()
    $(".level2").fadeOut()
    $(".hero").addClass("hidden")
    $("#home").fadeOut 400
    #$('#content').show()

  socket.on "deactivate", (msg) ->
    setRandomHero()
    $("#home").fadeIn 400
    $("#level1").fadeIn()
    $(".level2").fadeOut()
    #$('#content').hide()

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
        setRandomHero()

  random = (min, max) ->
    if !max
      max = min
      min = 0
    Math.round Math.random() * (max - min) + min

  setRandomHero = ->
    i = random($(".hero").length)
    while i == $('.hero:not(.hidden)').index()
      i = random($(".hero").length)
    $(".hero").addClass("hidden")
    $($(".hero")[i]).removeClass("hidden")

  a.computeTiles = ->
    j = -1
    widthOpts0 = [128, 128*2, 128*2, 128*3]
    heightOpts0 = [128, 128*2, 128*2, 128*3]
    x0 = 0
    y0 = 0
    cols = 4
    rows = 4
    widthOpts = $(widthOpts0).toArray()
    grid = new Array()
    i = 0
    while i < cols
      grid[i++] = new Array()

    while ++j < $(".level1").length
      div = $(".level1")[j]
      if(j % cols == 0)
        widthOpts = $(widthOpts0).toArray()
        heightOpts = $(heightOpts0).toArray()
      i = random(widthOpts.length - 1)
      spacingX = widthOpts[i]
      widthOpts.remove(i)
      i = random(heightOpts.length - 1)
      spacingY = heightOpts[i]
      heightOpts.remove(i)
      #spacingY = $(window).height() / ($(".level1").length / cols)
      #spacingY = $(window).height() / ($(".level1").length / cols)
      $(div).width spacingX
      $(div).height spacingY
      spacingY = $(div).height()
      $(div).data "left", x0
      $(div).data "top", y0
      #console.log div
      #console.log "#{j} --> #{j%cols}, #{parseInt(j/cols)}"
      grid[j % cols][parseInt( j / cols )] = {
        width: $(div).width(),
        height: $(div).height(),
        x: x0,
        y: y0,
        bottom: y0 + $(div).height()
      }
      $(div).data "w0", spacingX
      $(div).data "h0", spacingY
      $(div).data "x0", x0
      $(div).data "y0", y0
      if x0 + spacingX >= $(window).width() || y0 > 0 || j / cols == 1
        y = grid[(j%cols)][parseInt( (j + 1) / cols ) - 1].bottom
        if y > y0
          y0 = y
      if x0 + spacingX >= $(window).width() - 127
        x0 = 0
      else
        x0 += $(div).width()
      if spacingY < spacingX
        $(div).data "tall", false
        $(div).children("img").css "width", "100%"
        $(div).children("img").css "height", "auto"
      else
        $(div).data "tall", true
        $(div).children("img").css "width", "auto"
        $(div).children("img").css "height", "100%"
    grid

  a.animateTiles = ->
    $(".level1").each ->
      me = @
      setTimeout ->
        $(me).animate {
          left: $(me).data("left"),
          top: $(me).data("top")
        }, 400, ->
          if $(me).data "tall"
            $(me).children("img").css "width", "auto"
            $(me).children("img").css "height", $(me).height()
          else
            $(me).children("img").css "width", $(me).width()
            $(me).children("img").css "height", "auto"
          $(me).css "overflow", "hidden"
      , $(me).index() * 100
        
  a.resetTiles= ->
    $(".level1").each ->
      me = @
      $(me).animate {
        left: -1000
        top: -1000
      }, 900

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
    a.computeTiles()

  $("#home").click ->
    $('#home').hide()
    $('#level1').fadeIn(500)
    a.animateTiles()

  $('.level1').click () ->
    me = @
    $('#level1').fadeOut 400, () ->
      $(".level2.#{$(me).data('sub')}").fadeIn 400

