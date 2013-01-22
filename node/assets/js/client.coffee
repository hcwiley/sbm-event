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
  a.socket = socket

  socket.on "connection", (msg) ->
    socket.emit "pageId", a.pageId
    socket.emit "getContent", a.pageId

  socket.on "activate", (msg) ->
    a.resetTiles()
    setRandomHero()
    $("#home").fadeIn 400
    $("#level1").fadeOut()
    a.isActive = true;
    #$("#level1").fadeIn()
    #$(".level2").fadeOut()
    #$(".hero").addClass("hidden")
    #$("#home").fadeOut 400
    #$('#content').show()

  socket.on "deactivate", (msg) ->
    #setRandomHero()
    a.isActive = false;
    $("#home").fadeIn 400
    $("#level1").fadeOut()
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
        socket.emit "heroes", {
          id: a.pageId,
          heroes: $('#home').html()
        }
        setRandomHero()

  setRandomHero = ->
    i = random($(".hero").length - 1)
    while i == $('.hero:not(.hidden)').index()
      i = random($(".hero").length - 1)
    $(".hero").addClass("hidden")
    $($(".hero")[i]).removeClass("hidden")
    socket.emit "hero", {id: a.pageId, i:i }

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
      $(div).attr "left", x0
      $(div).attr "top", y0
      #console.log div
      #console.log "#{j} --> #{j%cols}, #{parseInt(j/cols)}"
      grid[j % cols][parseInt( j / cols )] = {
        width: $(div).width(),
        height: $(div).height(),
        x: x0,
        y: y0,
        bottom: y0 + $(div).height()
      }
      $(div).attr "w0", spacingX
      $(div).attr "h0", spacingY
      $(div).attr "x0", x0
      $(div).attr "y0", y0
      if x0 + spacingX >= $(window).width() || y0 > 0 || j / cols == 1
        y = grid[(j%cols)][parseInt( (j + 1) / cols ) - 1]?.bottom
        if y > y0
          y0 = y
      if x0 + spacingX >= $(window).width() - 127
        x0 = 0
      else
        x0 += $(div).width()
      if spacingY < spacingX
        $(div).attr "tall", false
        $(div).children("img").css "width", "100%"
        $(div).children("img").css "height", "auto"
      else
        $(div).attr "tall", true
        $(div).children("img").css "width", "auto"
        $(div).children("img").css "height", "100%"
    socket.emit "buckets", {
      id: a.pageId,
      buckets: $('#level1').html()
    }
    grid

  doBucket = (json, i) ->
    for j, level1 of json
      #console.log "#{j} -> "
      div = $(_.template($('#square-template').html(), level1))
      $('#level1').append(div)
      $(div).attr "id", "#{i}-#{j}"
      $(div).click ->
        socket.emit "click", { id: a.pageId, div: $(@).index() }
        a.handleBucketClick(@)
    a.computeTiles()

  $("#home").click ->
    if a.isActive
      a.socket.emit "click", { id: a.pageId, div: "#home" }
      $('#home').hide()
      $('#level1').fadeIn(500)
      a.animateTiles()

  $("#level1").on "scroll", (e)->
    a.socket.emit "scroll", "#{$(@).scrollTop()}"

  $('.level1').click () ->
    me = @
    a.socket.emit "click", $(me).index()
    $('#level1').fadeOut 400, () ->
      $(".level2.#{$(me).attr ('sub')}").fadeIn 400

