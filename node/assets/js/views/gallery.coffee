#= require ../underscore
# =require ../backbone
# =require ../jquery

GalleryView = Backbone.View.extend({
  #template: _.template $('#gallery-template').html()
  initialize: (attrs) ->
    console.log "ima thing"
    @.objs = attrs.objs
    @.$el = attrs.el
    @.render()

  render: ->
    count = 0
    @.$el.html ""
    for obj in @.objs
      vars = obj
      vars.pos = "left: " + ( (count % 4) * ( 200 + 40 )+ 100 ) + "px;"
      vars.pos += "top: " + ( ( (count / 4) * 400) - 250 ) + "px;"
      div = $(_.template($('#gallery-template').html(), obj))
      $(div).data 'data', obj
      @.$el.append div
      console.log 'got the template'
      count++
    
    #@.$el.html html
})

@GalleryView = GalleryView
