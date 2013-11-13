Node RocketIO Client
====================
Ruby's [Sinatra::RocketIO](https://github.com/shokai/sinatra-rocketio) client library for Node.js

* https://github.com/shokai/node-rocketio-client
* https://npmjs.org/package/rocketio-client


How to use
----------
see sample/sample.coffee

```coffee
RocketIO = require 'rocketio-client'
io = new RocketIO()
io.connect 'http://localhost:5000'

io.on 'connect', (io)->
  console.log "connect!! (#{io.type})"
  io.push 'hello', 'hello world'

io.on 'echo', (data)->
  console.log "echo> #{data}"
```