#= require ../underscore
# =require ../backbone
# =require ../jquery

Hand = Backbone.Model.extend({
  defaults: {
    x: 0,
    y: 0,
    z: 0,
    cursor: "",
    parent: "",
  }
  
  initialize: ->
    console.log "i'm a hand object damn it"
    @.on 'change', @moved

  moved: ->
    me = @.attributes
    me.cursor.css 'left', me.x - me.cursor.width() / 2
    me.cursor.css 'top', me.y - me.cursor.height() / 2
    if a.grabbed?.hand == @
      a.grabbed.entry.center @
      a.grabbed.entry.scaleTo @, me.parent.otherHand(@)
      a.emailDrop?.checkOver a.grabbed.entry
    else
      a.grabbables.isOver @

  doPushCheck: ->
    me = @.attributes
    push = me.parent?.attributes.torso?.z - me.z
    push = map push, 0, 700, 0, 100
    scale = map push, 0, 100, 10, 100

    me.cursor.width scale
    me.cursor.height scale

    # lets check and see if they pushed
    pushedThresh = 60
    if push > pushedThresh
      me.cursor.addClass 'pushed'
      a.grabbables.isPushed @
    else
      me.cursor.removeClass 'pushed'
      a.grabbables.isPulled @

  x: ->
    @.attributes.x
  y: ->
    @.attributes.y
  z: ->
    @.attributes.z
})

User = Backbone.Model.extend({
  defaults: {
    leftHand: new Hand(),
    rightHand: new Hand(),
    torso: {},
    status: ""
  }
  
  initialize: (attrs) ->
    @.attributes.leftHand.set {
      cursor: attrs.leftCursor
      , parent: @
    }
    @.attributes.rightHand.set {
      cursor: attrs.rightCursor
      , parent: @
    }

    console.log 'i live. you die...'
    @.on 'change:leftHand', @leftMoved
    @.on 'change:rightHand', @rightMoved
    @.on 'change:torso', @torsoMoved
    @.on 'change:status', @statusUpdated

  updatePosition: (data) ->
    me = @.attributes
    # want to scale this more so its easier to hit the corners
    wUpper = $(window).width() * 1.3
    hUpper = $(window).height() * 1.3
    wLower = $(window).width() - wUpper
    hLower = $(window).height() - hUpper
    data.hands.left.x = map data.hands.left.x, 0, 640, wLower, wUpper
    data.hands.right.x = map data.hands.right.x, 0, 640, wLower, wUpper
    data.hands.left.y = map data.hands.left.y, 0, 320, hLower, hUpper
    data.hands.right.y = map data.hands.right.y, 0, 320, hLower, hUpper
    data.hands.left.z  = parseFloat data.hands.left.z
    data.hands.right.z = parseFloat data.hands.right.z
    @.set {
      torso : data.torso
    }
    me.leftHand.set {
      x: data.hands.left.x,
      y: data.hands.left.y,
      z: data.hands.left.z
    }
    me.rightHand.set {
      x: data.hands.right.x,
      y: data.hands.right.y,
      z: data.hands.right.z
    }
  
  statusUpdated: () ->
    me = @.attributes
    $("#status").text me.status
  
  torsoMoved: ->
    me = @.attributes
    # lets do some push threshhold and hand scale mapping
    # left then right
    me.leftHand.doPushCheck()
    me.rightHand.doPushCheck()

  otherHand: (thisHand) ->
    me = @.attributes
    if thisHand == me.leftHand
      return me.rightHand
    me.leftHand


})

@User = User
@Hand = Hand
