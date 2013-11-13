events = require 'events'
request = require 'request'

class RocketIO extends events.EventEmitter
  constructor: ->
    @type = 'websocket'
    @config = {}

  connect: (url, opts={type: 'websocket'})=>
    request "#{url}/rocketio/settings", (err,res,body)=>
      return if err or res.statusCode != 200
      @config = JSON.parse body
      @io = switch opts.type
           when 'websocket'
             new WebSocketIO(@)
           when 'comet'
             new CometIO(@)
      @io.on 'connect', =>
        @emit 'connect', @
      @io.on 'disconnect', =>
        @emit 'disconnect', @

  push: (type, data)=>
    @io.push type, data

class WebSocketIO extends events.EventEmitter
  WebSocket = require 'ws'

  constructor: (rocketio)->
    @rocketio = rocketio
    @connecting = false
    @on 'disconnect', =>
      setTimeout =>
        @connect()
      , 5000
    @connect()

  connect: ->
    @ws = new WebSocket @rocketio.config.websocket
    @ws.on 'error', (err)=>
      @connecting = false
      @emit 'disconnect'
    @ws.on 'close', =>
      @connecting = false
      @emit 'disconnect'
    @ws.on 'open', =>
      @connecting = true
      @emit 'connect'
    @ws.on 'message', (data,flags)=>
      data = JSON.parse data
      @rocketio.emit data.type, data.data

  push: (type, data)->
    return unless @connecting
    @ws.send JSON.stringify({type: type, data: data})

module.exports = RocketIO
