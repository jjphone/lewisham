( () ->
	app = angular.module("app", [ 'ngCookies', 'ngRoute', 'ngAnimate', 'ng-rails-csrf', 'ngSanitize', \
	'app.renderDirectives', 'app.funDirectives', \
	'app.factories', \
	'app.content', "app.users", "app.chats" ])

	#app.siteUrl = "http://kogarah.localhost/"
	#app.siteTitle = "Trainbuddy"


	app.config(["$httpProvider", ($httpProvider) -> 
		authToken = $("meta[name=\"csrf-token\"]").attr("content")
		$httpProvider.defaults.headers.common["X-CSRF-Token"] = authToken
	])

	app.filter('capitalize', () ->
		(input, scope) ->
			input.charAt(0).toUpperCase() + input.substring(1).toLowerCase() if input?
	)

	app.config(["$routeProvider", '$locationProvider', ($routeProvider, $locationProvider) -> 
		$locationProvider.html5Mode(true)
		$routeProvider.when( "/", {
			templateUrl:  "/assets/layouts/ngView.html",
			resolve: { load: loadView }
		
		}).otherwise( {
			templateUrl: "/assets/layouts/ngView.html",
			resolve: { load: loadView }
		} )

	])

	loadView = ["Jsonp",  (Jsonp) -> 
		Jsonp.setView()
	]
			
	app.directive "test", () ->
		restrict: "A",
		transclude: true,
		template:"<div class='lime' style='margin:50px' > <a class='yellow' style='margin:50px'>link</a><ng-transclude></ng-transclude></div>"


).call(this)