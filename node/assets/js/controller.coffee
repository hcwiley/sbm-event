
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
  socket = io.connect "http://localhost" 

  socket.on "connection", (data) ->
    socket.emit "getPages", ""

  socket.on "activePages", (data) ->
    $(".btn-primary:not('#temp')").remove()
    count = Object.keys data
    for i in count
      console.log data[i]
      page = data[i]
      button = $("#temp").clone()
      $(button).removeClass("hidden").removeAttr("id").find(".pageId").text(page)
      $('#main').append(button)
      $(button).data "id", i
      $(button).click ->
        socket.emit "clickedPage", $(@).data "id"
    
    
  
  $('#goButton').click ->
    socket.emit "updatePage", $("#pageSelector").val()
