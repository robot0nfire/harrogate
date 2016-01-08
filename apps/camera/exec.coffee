daylite    = require_harrogate_module '/shared/scripts/daylite.coffee'
AppCatalog = require_harrogate_module '/shared/scripts/app-catalog.coffee'
Png = require('png').Png;
fs = require 'fs'
Config = require_harrogate_module 'config.coffee'
Directory = require AppCatalog.catalog['Host Filesystem'].path + '/directory.coffee'
HostFileSystem = require AppCatalog.catalog['Host Filesystem'].path + '/host-fs.coffee'
TargetApp = AppCatalog.catalog['Target information'].get_instance()
Workspace = require AppCatalog.catalog['Programs'].path +  '/workspace.coffee'
events = AppCatalog.catalog['Camera'].event_groups.camera_events.events
console.log events

clients = 0
latest_camera_frame = null

daylite.subscribe 'camera/frame_data', (msg) ->
  if not namespace?
    return
  png = new Png(msg.data, msg.width, msg.height, 'bgr');
  png.encode (data, error) ->
    if error
      console.log "Error: #{error.toString()}"
      return
    latest_camera_frame = data.toString 'binary'
    
    repacked_msg =
      width: msg.width
      height: msg.height
    namespace.emit events.frame_arrived.id, repacked_msg

Express = require 'express'
ServerError = require_harrogate_module '/shared/scripts/server-error.coffee'


# the currently runned program
running = null
running_process = null

# the socket.io namespace
namespace = null
client = null

# the runner router
router = Express.Router()

# get the current graphics window
router.get '/', (request, response, next) ->
  response.setHeader "Cache-Control", "no-cache, no-store, must-revalidate"
  response.setHeader "Pragma", "no-cache"
  response.setHeader "Expires", "0"
  if latest_camera_frame?
    response.writeHead 200, { 'Content-Type': 'image/png' }
    response.end latest_camera_frame, 'binary'
  else
    response.writeHead 404, { 'Content-Type': 'application/json' }
    response.end "#{JSON.stringify(error: 'No camera data')}", 'utf8'


module.exports =
  event_init: (event_group_name, ns) ->
    namespace = ns
    return

  init: (app) =>
    # add the router
    app.web_api.camera['router'] = router
    return

  exec: ->
    return
