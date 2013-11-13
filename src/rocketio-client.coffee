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

class CometIO extends events.EventEmitter
  constructor: (rocketio)->
    @rocketio = rocketio
    @post_queue = []
    @on '__session_id', (id)=>
      @session_id = id
      @emit 'connect'
    @get()
    setInterval =>
      @flush()
    , 1000

  get: ->
    url = switch typeof @session_id
          when 'string'
            @rocketio.config.comet+"?session=#{@session_id}"
          else
            @rocketio.config.comet
    request url, (err,res,body)=>
      if err or res.statusCode != 200
        setTimeout =>
          @get()
        , 10000
        return
      data_arr = JSON.parse body
      return unless data_arr instanceof Array
      setTimeout =>
        @get()
      , 10
      for data in data_arr
        @emit data.type, data.data
        @rocketio.emit data.type, data.data

  push: (type, data)->
    return unless @session_id
    @post_queue.push {type:type, data:data}

  flush: ->
    return if @post_queue.length < 1
    post_data = {
      json: JSON.stringify({session: @session_id, events: @post_queue})
    }
    request.post {url: @rocketio.config.comet, form: post_data}, (err,res,body)=>
      return if err or res.statusCode != 200
      @post_queue = []

module.exports = RocketIO
