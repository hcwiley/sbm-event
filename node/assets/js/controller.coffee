
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

  socket.on "connection", (data) ->
    socket.emit "getPages", ""

  $("#cycle").click () ->
     socket.emit "cycle", "2"

  socket.on "activePages", (data) ->
    $(".scrn").remove()
    count = Object.keys data
    for i in count
      console.log data[i]
      page = data[i]
      button = $("#temp").clone()
      $(button).removeClass("hidden").removeAttr("id").find(".pageId").text(i)
      $(button).addClass('scrn')
      $('#main').append(button)
      $(button).data "id", data[i]
      $(button).click ->
        socket.emit "clickedPage", $(@).data "id"
    
    
  
  $('#goButton').click ->
    socket.emit "updatePage", $("#pageSelector").val()
