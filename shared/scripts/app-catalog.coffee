url = require 'url'
fs = require 'fs'

class AppCatalog
  constructor: ->
    @catalog = {}
    @catalog_4_client = {}
    @apps_base_path = './apps'
    @apps_nodejs_route_base = '/apps'
    @apps_angularjs_route_base = '/apps'

    apps = fs.readdirSync @apps_base_path
    for app in apps
      path = "#{@apps_base_path}/#{app}"
      continue if !fs.statSync(path).isDirectory()

      data = fs.readFileSync "#{path}/manifest.json", 'utf8'
      if not data?
        console.log "Could not read #{path}/manifest.json"
        continue

      manifest = JSON.parse data
      if not manifest?
        console.log "#{path}/manifest.json is malformed"
        continue

      @catalog[manifest['name']] =
        name: manifest['name']
        path: "#{path}"
        priority: manifest['priority'] ? 0
        url: "/##{@apps_angularjs_route_base}/#{app}"
        angularjs_route: "#{@apps_angularjs_route_base}/#{app}"
        nodejs_route: "#{@apps_nodejs_route_base}/#{app}"
        icon: "/#{path}/#{manifest['icon']}" if manifest['icon']?
        fonticon: manifest['fonticon'] if manifest['fonticon']?
        description: manifest['description']
        category: manifest['category']
        hidden: manifest['hidden']
        navbar: manifest['navbar']
        web_api: manifest['web_api'] if manifest['web_api']?
        exec_path: "#{path}/#{manifest['exec']}"
        get_instance: -> require "../../#{@exec_path}"

      # There might be a better strategy than to create two catalogs.
      # However they are supposed to be read-only, so this is the more performant way
      @catalog_4_client[manifest['name']] =
        name: manifest['name']
        priority: manifest['priority'] ? 0
        url: "/##{@apps_angularjs_route_base}/#{app}"
        angularjs_route: "#{@apps_angularjs_route_base}/#{app}"
        nodejs_route: "#{@apps_nodejs_route_base}/#{app}"
        icon: "/#{path}/#{manifest['icon']}" if manifest['icon']?
        fonticon: manifest['fonticon'] if manifest['fonticon']?
        description: manifest['description']
        category: manifest['category']
        hidden: manifest['hidden']
        navbar: manifest['navbar']
        angular_ctrl: "#{path}/#{manifest['angular_ctrl']}" if manifest['angular_ctrl']
        web_api: manifest['web_api'] if manifest['web_api']?

  handle: (request, response) ->
    callback = url.parse(request.url, true).query['callback']
    # should we return JSON or JSONP (callback defined)?
    if callback?
      response.writeHead 200, { 'Content-Type': 'application/javascript' }
      return response.end "#{callback}(#{JSON.stringify(@catalog_4_client)})", 'utf8'
    else
      response.writeHead 200, { 'Content-Type': 'application/json' }
      return response.end "#{JSON.stringify(@catalog_4_client)}", 'utf8'

module.exports = new AppCatalog