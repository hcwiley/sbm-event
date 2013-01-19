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

  a.tileLevel1 = tileLevel1 = ->
    j = 0
    $(".level1").each ->
      div = @
      cols = 5
      rows = 4
      spacingX = $(window).width() / cols
      spacingY = $(window).height() / ($(".level1").length / cols)
      $(div).width spacingX
      $(div).height spacingY
      y0 = 0
      x0 = 0
      $(div).css "left", ( spacingX * ( j % cols )) + x0
      $(div).css "top", ( spacingY *  parseInt( j / cols ) ) + y0
      j++

  doBucket = (json, i) ->
    for j, level1 of json
      #console.log "#{j} -> "
      div = $(_.template($('#square-template').html(), level1))
      $('#level1').append(div)
      tileLevel1()
      aTime = 400
      $(div).attr "id", "#{i}-#{j}"
      $(div).click ->
        if $(@).data "open"
          $(@).data "open", false
          $(@).animate {
            left: $(@).data("x0"),
            top: $(@).data("y0"),
            width: $(@).data("w0"),
            height: $(@).data("h0"),
            "z-index": 1
          }, aTime
          #setTimeout ->
            #$('.level1').fadeIn(aTime)
          #, aTime

        else
          $(@).data "open", true
          #$('.level1').not(@).hide()
          $(@).data "w0", $(@).width()
          $(@).data "h0", $(@).height()
          $(@).data "x0", $(@).css "left"
          $(@).data "y0", $(@).css "top"
          toLeft = 0 - $(@).data "x0"
          toTop = 0 - $(@).data "y0"
          $(@).css "z-index", 100
          $(@).animate {
            top: 0,
            left: 0,
            width: $(window).width(),
            height: $(window).height(),
          }, 400

  $("#home").click ->
    $('#home').hide()
    $('#level1').fadeIn(500)

  $('.level1').click () ->
    me = @
    $('#level1').fadeOut 400, () ->
      $(".level2.#{$(me).data('sub')}").fadeIn 400

