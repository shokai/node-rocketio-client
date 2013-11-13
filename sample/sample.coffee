## start server
## cd ../server && cat README.md

RocketIO = require '../'
io = new RocketIO()
io.connect 'http://localhost:5000'

io.on 'connect', (io)->
  console.log "connect!! (#{io.type})"

io.on 'disconnect', ->
  console.log "disconnected.. (#{io.type})"

io.on 'echo', (data)->
  console.log "echo> #{data}"

process.stdin.setEncoding 'utf8'
process.stdin.on 'data', (data)->
  io.push 'hello', data.replace(/[\r\n]/g, '')
