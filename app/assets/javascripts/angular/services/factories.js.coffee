( () ->
	app = angular.module('app.factories', ['ngRoute'])
	app.run(["$rootScope", "$route", "$location", ($rootScope, $route, $location) -> 
		###
		$rootScope.$on '$includeContentLoaded', ()->
		$rootScope.$on '$viewContentLoaded', ()->
		$rootScope.$on '$locationChangeSuccess', ()->	
		$rootScope.$on '$routeChangeSuccess', ()->
		###
		$location.skipReload = (lastRoute) ->
			un = $rootScope.$on('$locationChangeSuccess', (event) ->
				console.log "----- ##  $location.skipReload -> event( $locationChangeSuccess event )"
				$route.current = lastRoute
				un()
			)
			$location
	])

	app.factory("ViewService", [ "$route", "$location", "$cookies", "$rootScope", ($route, $location, $cookies, $rootScope) ->
		{ view:  { source: "default", site_url: "kogarah.localhost", current_user: null, path: null, flash: null, template: "", data: "", title: "", syn_url: false }, 
		links: { root: "/", about: "/about", contact: "/contact", help: "/help", signin:"/signin", signup: "/signup"},
		pages: { menu_signin: "/assets/layouts/signin_menu.html", menu_user: "/assets/layouts/user_menu.html"},
		token: {},
		persist: false,
		set: ( data, xsrf ) ->
			this.view = angular.copy(data)
			this.view.site_url = "http://kogarah.localhost/" unless this.view.site_url?
			this.view.title = "Trainbuddy" unless this.view.title?
			this.token = xsrf if xsrf
			console.log("------- ViewService.set  - done : this.view =" , this.view)
			return this
		,
		pushStateURL: (caller) ->
			console.log "------ #.  After " +caller+ ".then( run pushStateURL )"
			if this.view? and this.view.path.current? and this.view.syn_url
				console.log("-------- ##. jsonp:pushStateURL() :: override location by -> view.path.current = ", this.view.path.current)
				this.view.syn_url = false
				this.persist = true
				$location.skipReload($route.current).url(this.view.path.current).replace()
			console.log "ViewService.pushStateURL done"
		,
		refresh: () ->
			console.log "ViewService.refresh() called"
			$rootScope.$apply()
		,
		}
	])

	app.factory("Jsonp", ["ViewService", "$route", "$location", "$http", "$q", "$cookies", "$rootScope", \
	(ViewService, $route, $location, $http, $q, $cookies, $rootScope) -> 
		{ 
			vs: ViewService,
			connects: (q, config)->
				name = " ---- jsonp.connects()"
				conn = $http(config)
				conn.success( (data, status, header, config) ->
					console.log(name + " :: Success - data = ", data)
					q.resolve(data)
				).error( (data, status, header, config) ->
					console.log(name+ " :: Failed ! - status = " +status )
					q.reject(status)
				)
			, 
			request: (config) ->
				name = " ---- jsonp.request()"
				self = this
				q = $q.defer()
				q.promise.then( () ->
					ViewService.pushStateURL("Jsonp.http()")
				).then( () ->
					console.log "pushStateURL done"
				)	
				self.connects(q,config).then( (response) ->
					self.updateView(response)
				, (response) ->
					console.log(name+" :: Failed ! - response = ", response)
					ViewService.view.flash = {error: "Connection Error. status = " +response.status}
					ViewService.view.status = response.status
					ViewService.view.template = "/assets/layouts/error.html"
					q.reject("Error: jsonp.request")				
				)
			, 
			updateView: (response) ->
				ViewService.set(response.data, $cookies["XSRF-TOKEN"] )

			setView: () ->
				name = " ---- jsonp.setView()"
				if ViewService.persist
					console.log(name + " :: Persist view required")
					ViewService.persist = false
				else
					if window.viewPreload?
						console.log(name+" :: loading window.viewPreload")
						ViewService.set(window.viewPreload, $("meta[name=\"csrf-token\"]").attr("content") )
						window.viewPreload = null
					else
						console.log(name+" :: loading json request")
						if $route.current? then url_param = $route.current.params else url_param = null
						if url_param?
							url_param.callback = "JSON_CALLBACK"
						else
							url_param = {callback: "JSON_CALLBACK"}
						config = {method: "JSONP", url: $location.url(), params: url_param }
						this.request(config)
				console.log("-------------------setView :: ViewService = ", ViewService)
				ViewService.persist = false
				ViewService.view
		}
	])

).call(this)