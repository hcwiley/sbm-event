#= require ../underscore
# =require ../backbone
# =require ../jquery
# =require ../models/entry

Grabbables = Backbone.Collection.extend({
  model: Grabbable
  
  , isOver: (hand) ->
    @.forEach (e) ->
      e.checkOver hand

  , isPushed: (hand) ->
    @.forEach (e) ->
      if e.inMyBoundingBox hand
        e.pushed()
      else
        e.attributes.wasPushed = false

  , isPulled: (hand) ->
    @.forEach (e) ->
      if e.inMyBoundingBox hand
        e.pulled(hand)

  , notGrabbed: (grabbed) ->
    @.forEach (e) ->
      if e != grabbed
        e.attributes.el.addClass 'not-grabbed'

  , reset: () ->
    @.forEach (e) ->
      e.reset()

})


@Grabbables = Grabbables
