app = angular.module("app", [ 'ngCookies', 'ngRoute', 'ngAnimate', 'ng-rails-csrf', 'ngSanitize' ] )
app.siteUrl = "http://kogarah.localhost/"
app.siteTitle = "Trainbuddy"


app.config(["$httpProvider", ($httpProvider) -> 
	authToken = $("meta[name=\"csrf-token\"]").attr("content")
	$httpProvider.defaults.headers.common["X-CSRF-Token"] = authToken
])

app.filter('capitalize', () ->
	(input, scope) ->
		input.charAt(0).toUpperCase() + input.substring(1).toLowerCase() if input?
)



app.run(["$rootScope", "$route", "$location", ($rootScope, $route, $location) -> 
	$rootScope.$on '$includeContentLoaded', ()->
		console.log "------ event( $includeContentLoaded )"
	$rootScope.$on '$viewContentLoaded', ()->
		console.log "------ event( $viewContentLoaded )"

	###
	$rootScope.$on '$locationChangeSuccess', ()->
		console.log "------ event( locationChangeSuccess )"
	$rootScope.$on '$routeChangeSuccess', ()->
		console.log "------ event( routeChangeSuccess )"
	###
	
	$location.skipReload = (lastRoute) ->
		un = $rootScope.$on('$locationChangeSuccess', (event) ->
			console.log "----- ##  $location.skipReload -> event( $locationChangeSuccess event )"
			$route.current = lastRoute
			un()
		)
		$location
])
###
app.config(["$routeProvider", '$locationProvider', ($routeProvider, $locationProvider) -> 

	$locationProvider.html5Mode(true)
	$routeProvider.when("/help", { 
		templateUrl:  "/assets/layouts/ngView.html",
		resolve: {load: loadView}
	}).when("/about", {
		templateUrl:  "/assets/layouts/ngView.html",
		resolve: {load: loadView}
	}).when("/home", {
		templateUrl:  "/assets/layouts/ngView.html",
		resolve: {load: loadView}
	}).when("/contact", {
		templateUrl:  "/assets/layouts/ngView.html",
		resolve: {load: loadView}

	}).when("/pages", {
		templateUrl:  "/assets/layouts/ngView.html",
		resolve: {load: loadView}


	}).when("/users", {
		templateUrl: "/assets/layouts/ngView.html",
		resolve: {load: loadView},
		controller: "usersCtrl", controllerAs: "users"
	}).when("/users/:id", {
		templateUrl:  "/assets/layouts/ngView.html",
		resolve: {load: loadView},
		controller: "usersCtrl", controllerAs: "users"
	}).when("/users/:id/edit", {
		templateUrl:  "/assets/layouts/ngView.html",
		resolve: {load: loadView} ,
		controller: "usersCtrl", controllerAs: "users"
		
	}).when("/signin", {
		templateUrl:  "/assets/layouts/ngView.html",
		resolve: {load: loadView},
		controller: "sessionsCtrl",	controllerAs: "sessions"
	}).when("/sessions", {
		templateUrl:  "/assets/layouts/ngView.html",
		resolve: {load: loadView},
		controller: "sessionsCtrl", controllerAs: "sessions"

	}).when("/chats", {
		templateUrl:  "/assets/layouts/ngView.html",
		resolve: { load: loadView } 
	}).when("/chats/:id", {
		templateUrl:  "/assets/layouts/ngView.html",
		resolve: {load: loadView} 

	}).when("/search", {
		templateUrl:  "/assets/layouts/ngView.html",
		resolve: { load: loadView },
		controller: "searchCtrl", controllerAs: "search"
	
	}).when("/", {
		templateUrl:  "/assets/layouts/ngView.html",
		resolve: { load: loadView },
		#controller: "pageCtrl", controllerAs: "pages"	
		controller: "contentCtrl", controllerAs: "content"
	})
	.otherwise(
		templateUrl:  "/assets/layouts/ngView.html",
		resolve: { load: loadView },
		controller: "pageCtrl", controllerAs: "pages"		
])
###


app.factory("ViewService", [ "$route", "$location", "$cookies", ($route, $location, $cookies) ->
	{ view:  { source: "json", site_url: "kogarah.localhost", current_user: null, path: null, flash: null, template: "", data: "", title: "", syn_url: false }, 
	links: { root: "/", about: "/about", contact: "/contact", help: "/help", signin:"/signin", signup: "/signup"},
	pages: { menu_signin: "/assets/layouts/signin_menu.html", menu_user: "/assets/layouts/user_menu.html"},
	token: {},
	persist: false,
	set: ( data, xsrf ) ->
			this.view = angular.copy(data)
			this.view.site_url = app.siteUrl unless this.view.site_url?
			this.view.title = app.siteTitle unless this.view.title?
			this.token = xsrf if xsrf
			console.log("------- ViewService.set  - end : this.view =" , this.view)
			return this

	, pushStateURL: (caller) ->
			console.log "------ #.  After " +caller+ ".then( run pushStateURL )"
			if this.view? and this.view.path.current? and this.view.syn_url
				console.log("-------- ##. jsonp:pushStateURL() :: override location by -> view.path.current = " + this.view.path.current)
				this.view.syn_url = false
				this.persist = true
				$location.skipReload($route.current).url(this.view.path.current).replace()
	}
	
]) 

app.factory("Jsonp", ["$route", "$location", "$http", "$q", "$cookies","ViewService", "$rootScope", ($route, $location, $http, $q, $cookies,  ViewService, $rootScope) -> 
	{ vs: ViewService,
	setView: () ->
		1

	}
])	



contentCtrl = app.controller("contentCtrl", [ "$scope", "$rootScope", "$route", "$location", "$anchorScroll", "$q", "$cookies", "$animate", ($scope, $rootScope, $route, $location, $anchorScroll, $q, $cookies, $animate) ->
	content = this

	content.demo = () ->
		#ViewService.pages.menu_signin
		"demo"

	content
])



loadView = ["Jsonp",  (Jsonp) -> 
	Jsonp.setView()
]


# default.html.erb - topbar
app.directive "topbar", () ->
	restrict: "A",
	controller: "contentCtrl", controllerAs: "content",
	templateUrl: "/assets/layouts/topbar.html"

app.directive("userMenu", ["ViewService", (ViewService)  ->
	restrict: "A",
	require: "^topbar",
	templateUrl: "/assets/layouts/user_menu.html"
])

app.directive "canvasToggle", [ "$animate", ($animate) ->
	restrict: "C",
	link: (scope, elem, attrs, event ) ->
		elem.on 'click', () ->
			c = elem.parent()
			if c.hasClass("canvas-toggled")
				$animate.removeClass(c, "canvas-toggled").then(
					scope.$apply()
				)
			else
				$animate.addClass(c, "canvas-toggled").then(
					scope.$apply()
				)
]

app.directive "canvas", ["$animate", ($animate) ->
	restrict: "C",
	link: (scope, elem, attrs, event) -> 
		elem.on 'mouseenter', () ->
			$animate.addClass(elem, "show").then(
				scope.$apply()
			)
		elem.on 'mouseleave', () ->
			$animate.removeClass(elem, "show").then(
				scope.$apply()
			)
]


	
