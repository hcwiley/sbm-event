#= require ../underscore
# =require ../backbone
# =require ../jquery
# =require ../views/gallery

Grabbable = Backbone.Model.extend({
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
    isGrabbed: false,
    isGrabbable: true,
    el: "",
    left: 0,
    right: 0,
    top: 0,
    bottom: 0
  }

  initialize: (attrs) ->
    @.on 'over', @.over
    @.on 'pushed', @.pushed
    @.on 'pulled', @.pulled
    @.on 'change:x', @.updateX
    @.on 'change:y', @.updateY
    @.on 'change:width', @.updateWidth
    @.on 'change:el', @.updateEl
    @.set {
      x: attrs.x0
      y: attrs.y0
      el: attrs.el
    }
    @.attributes.width = attrs.width0
    @.attributes.height = attrs.height0
    @.setCorners()
    @.updateEl()
    console.log "im such a drag..." 

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

  scaleTo: (controlHand, otherHand) ->
    me = @.attributes
    diff = controlHand.x() - otherHand.x()
    if diff < 0
      diff *= -1
    @.set {
      width: diff
    }

  inMyBoundingBox: (hand) ->
    me = @.attributes
    if hand?.x() > me?.left && hand?.x() < me?.right
      if hand?.y() > me.top && hand?.y() < me?.bottom
        return true
    return false

  checkOver: (hand) ->
    me = @.attributes
    if hand && me.isGrabbable
      if @.inMyBoundingBox hand
          return @.trigger 'over'
    me.el.removeClass 'over' 

  over: ->
    me = @.attributes
    #console.log "over my dead body"
    me.el.addClass 'over'

  pushed: ->
    me = @.attributes
    if a.grabbed
      a.grabbed.entry.drop()
    else
      me.wasPushed = true

  pulled: (hand) ->
    me = @.attributes
    if !a.grabbed && me.wasPushed && a.lastGrabbed != @
      @.grab hand

  grab: (hand) ->
    me = @.attributes
    a.grabbed = {
      entry: @,
      hand: hand
    }
    a.entries.notGrabbed @
    a.lastGrabbed = false
    me.el.addClass 'grabbed'
    console.log "you grabbing me?: #{me.el.index()}"
    $('#info .title').text me.title
    $('#info .desc').text me.desc
    if me.title
      doGrabAnimations()
      $('#info img.map').attr('src', 'http://maps.googleapis.com/maps/api/staticmap?center='+me.loc+', New Orleans,LA&markers=color:blue%7Clabel:S%7C'+me.loc+', New Orleans,LA&zoom=16&size=500x250&sensor=false');
    @.trigger 'wasGrabbed'

  drop: ->
    me = @.attributes
    a.grabbed = false
    a.lastGrabbed = @
    me.el.removeClass 'grabbed'
    a.entries.reset()
    console.log "you dropped me!: #{me.el.index()}"
    doDropAnimations()
    @.trigger 'wasDropped'

  reset: ->
    me = @.attributes
    me.el.removeClass 'not-grabbed'


})


Entry = Grabbable.extend()

CornerEntry = Grabbable.extend({
  initialize: (attrs) ->
    @.on 'over', @.over
    @.on 'pushed', @.pushed
    @.on 'pulled', @.pulled
    @.on 'change:x', @.updateX
    @.on 'change:y', @.updateY
    @.on 'change:el', @.updateEl
    @.set {
      width: attrs.width0
      height: attrs.height0
      x: attrs.x0
      y: attrs.y0
      el: attrs.el
      gallery: attrs.el.data 'gallery'
    }
    @.setCorners()
    @.updateEl()
    console.log "corner stone..." 

  grab: (hand) ->
    me = @.attributes
    a.entries.notGrabbed @
    a.lastGrabbed = false
    me.el.addClass 'grabbed'
    console.log "youve cornered me?: #{me.el.index()}"

    d = $("#gallery")
    g_view = new GalleryView { el:d, objs: a.galleries["#{me.gallery}"] }

    @.trigger 'wasGrabbed'

})
@Grabbable = Grabbable
@CornerEntry = CornerEntry
@Entry = Entry
