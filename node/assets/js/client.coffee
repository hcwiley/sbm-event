#= require jquery
#= require isotope.min.js
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
    a.computeTiles()
    setRandomHero()
    $("#home").fadeIn 400
    $("#home").animate {
      opacity: 1
    }, 400
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
    $("#home").animate {
      opacity: .4
    }, 400
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
    widthOpts0 = [
      128, 128, 128, 128, 128, 128,
      256, 256, 256, 256, 256, 256, 256,
      384, 384
    ]
    #heightOpts0 = [128, 128*2, 128*2, 128*3]
    x = 0
    y = 0
    cols = 4
    rows = 4
    widthOpts = $(widthOpts0).toArray()
    grid = new Array()
    i = 0
    while i < cols
      grid[i++] = new Array()

    lastWidth = -1
    divs = $('.level1').toArray()
    while ++j < widthOpts0.length
      divI = random(divs.length)
      div = divs[divI]
      divs.remove(divI)
      #$(div).prependTo $("#level1")
      $(div).addClass("active")
      $(div).removeClass("hidden")
      #if(j % cols == 0)
        #widthOpts = $(widthOpts0).toArray()
        #heightOpts = $(heightOpts0).toArray()
      i = random(widthOpts.length - 1)
      width = widthOpts[i]
      #if width == 384
        #if ( y == 0 || y == 3 ) || ( x == 
          #while width == 384
            #i = random(widthOpts.length - 1)
            #width = widthOpts[i]
      widthOpts.remove(i)
      #if width == 128
        #doSmallBlock div, x, y
      #if width == 256
        #doMediumBlock div, x, y
      #if width == 384
        #doLargeBlock div, x, y

      $(div).width width - 20
      $(div).height width - 20

      grid[x][y] = {
        width: $(div).width(),
        height: $(div).height(),
        x: x,
        y: y,
        bottom: y + $(div).height()
      }
      $(div).attr "w0", width
      $(div).attr "h0", width
      $(div).attr "x0", x
      $(div).attr "y0", y
      $(div).attr "hidden", false
      $(div).css "opacity", 0

      #x += ( width / 128 )
      #if x > 7
        #x = 0
        #y += 1

    $(".level1:not(.active)").each ->
      #$(@).addClass "hidden"
      $(@).attr "hidden", true


    socket.emit "buckets", {
      id: a.pageId,
      buckets: $('#level1').html()
    }
    $("#level1").css("height", "auto")

  doBucket = (json, i) ->
    for j, level1 of json
      #console.log "#{j} -> "
      level1.text = level1.text || "foo"
      div = $(_.template($('#square-template').html(), level1))
      $('#level1').append(div)
      $(div).attr "id", "#{i}-#{j.toLowerCase().replace(".jpg","")}"
      $(div).click ->
        socket.emit "click", { id: a.pageId, div: $(@).index() }
        a.handleBucketClick(@)
    a.computeTiles()

  $('#level1').isotope
    itemSelector: '.level1',
    layoutMode : 'masonry'

  $("#home").click ->
    if a.isActive
      $('#home').fadeOut 100, ->
        $('#level1').fadeIn()
        setTimeout ->
          $(".level1").each ->
            $me = $(@)
            setTimeout ->
              $me.animate {
                opacity: 1
              }, 300
            , $me.index() * 200
        , 200
      a.socket.emit "click", { id: a.pageId, div: "#home" }
      #a.animateTiles()

  $(window).scroll ()->
    #console.log $(@).scrollTop()
    a.socket.emit "scroll", "#{$(@).scrollTop()}"

  $('.level1').click () ->
    me = @
    a.socket.emit "click", $(me).index()
    $('#level1').fadeOut 400, () ->
      a.handleBucketClick(me)
      #$(".level2.#{$(me).attr ('sub')}").fadeIn 400

