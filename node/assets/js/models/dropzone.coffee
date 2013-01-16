#= require ../underscore
# =require ../backbone
# =require ../jquery
# =require ../views/gallery

DropZone = Backbone.Model.extend({
  defaults: {
    width: 0,
    height: 0,
    width0: 0,
    height0: 0,
    x: 0,
    y: 0,
    x0: 0,
    y0: 0,
    data: {},
    el: "",
    left: 0,
    right: 0,
    top: 0,
    bottom: 0
  }

  initialize: (attrs) ->
    @.on 'over', @.over
    @.on 'change:x', @.updateX
    @.on 'change:y', @.updateY
    @.on 'change:width', @.updateWidth
    @.on 'change:el', @.updateEl
    @.set {
      el: attrs.el
    }
    @.attributes.x = attrs.x0
    @.attributes.y = attrs.y0
    @.attributes.width = attrs.width0
    @.attributes.height = attrs.height0
    @.setCorners()
    @.updateEl()
    console.log "drop it like its hot"

  updateEl: ->
    me = @.attributes
    if me.el.data 'data'
      @.set {
        title: me.el.data('data').title
        desc: me.el.data('data').description
        loc: me.el.data('data').location
        #link: me.el.data ('data').link
      }

  updateX: ->
    me = @.attributes
    @.setCorners()
    me.el.css 'left', me.x

  updateY: ->
    me = @.attributes
    @.setCorners()
    me.el.css 'top', me.y

  updateWidth: ->
    me = @.attributes
    @.setCorners()
    me.el.width me.width

  setCorners: ->
    me = @.attributes
    me.left = me.x
    me.right = me.x + me.width
    me.top = me.y
    me.bottom = me.y + me.height

  center: (loc) ->
    me = @.attributes
    cenx = loc.x() - (me.width / 2)
    @.set x: cenx
    ceny = loc.y() - (me.height / 2)
    @.set y: ceny

  inMyBoundingBox: (entry) ->
    me = @.attributes
    them = entry?.attributes
    #$('#status-box').html("<h1>#{me.left}, #{me.right}<br>#{them.left}, #{them.right}</h1>")
    if ( them?.left > me?.left && them?.left < me?.right ) || ( them?.right > me?.left && them?.right < me?.right )
      if ( them?.bottom > me.top && them?.top < me?.bottom ) || ( them?.top > me.top && them?.bottom < me?.bottom )
        return true
    return false

  checkOver: (entry) ->
    me = @.attributes
    if entry
      if @.inMyBoundingBox entry
          return @.trigger 'over'
    me.el.removeClass 'over' 

  over: ->
    me = @.attributes
    #console.log "over my dead body"
    me.el.addClass 'over'

})

@DropZone = DropZone
