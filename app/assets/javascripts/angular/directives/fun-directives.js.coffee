( () -> 
	app = angular.module('app.funDirectives', ['app.factories', 'app.content'])
	app.directive "ngMethod", ["Jsonp", (Jsonp) ->
		restrict: "A"
		link: (scope, elem, attrs, event) ->
			elem.on "click", ( event) ->
				event.preventDefault()
				config = {method: attrs.ngMethod, url: attrs.href}
				config.headers = {'Content-Type': 'application/json;charset=utf-8'} if attrs.ngMethod == 'patch'
				Jsonp.request(config)
	]

	app.directive "upload", ["$parse", "ViewService", ($parse, ViewService) ->
		restrict: "A",
		link: (scope, elem, attrs) ->
			elem.on("change", () -> 
				$parse(attrs.upload).assign(ViewService.view.data, elem[0].files )
				scope.$apply
				console.log("------ #upload : ......" , ViewService.view.data)
			)
	]
	app.directive "flash", () ->
		restrict: "E",
		controller: "contentCtrl", controllerAs: "content",
		templateUrl: "/assets/layouts/flash.html"
	# /template/layouts/flash.html
	app.directive "dismiss", [ "ViewService", (ViewService) ->
		restrict: "A",
		link: (scope, elem, attrs, event) ->
			elem.on 'click', () ->
				delete ViewService.view.flash[attrs.dismiss]
				ViewService.refresh()
	]

	# default.html.erb - topbar
	app.directive "topbar", () ->
		restrict: "A",
		controller: "contentCtrl", controllerAs: "content",
		templateUrl: "/assets/layouts/topbar.html"

	app.directive "userMenu", ()  ->
		restrict: "A",
		require: "^topbar",
		templateUrl: "/assets/layouts/user_menu.html"
	
	# canvas toggle + aside slide
	app.directive "canvasToggle", [ "$animate", ($animate) ->
		restrict: "C",
		link: (scope, elem, attrs, event ) ->
			elem.on 'click', () ->
				c = elem.parent().parent()
				console.log "canvasToggle - click "
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
	# scroll load pagination at /template/layout/pagination.html
	app.directive "scrolling", [ "$window", ($window) ->
		restrict: "A",
		link: (scope, elem, attrs, event) ->
			footerHeight = 80
			angular.element($window).on "scroll", (event) ->
				if scope.content.paginate_has_more() && !scope.content.j.vs.view.data.paginate.loading \
				&& this.pageYOffset >= $(document).height() - $(window).height() - footerHeight
					scope.content.paginate_page(scope.content.j.vs.view.data.paginate.page+1)
	]

	app.directive "fieldInput", () ->
		restrict: "A",
		scope: {field: "@fieldInput"},
		controller: "usersCtrl", controllerAs: "users",
		templateUrl: "/assets/users/func/field_error.html"

	# display chat form at chats/index.html, chats/show.html
	app.directive "chatForm", () ->
		restrict: "A",
		controller: "chatsCtrl", controllerAs: "chats",
		templateUrl: "/assets/chats/func/chat_form.html"

	#display existing chats in chat form slides at chats/index.html
	app.directive "reply", () ->
		restrict: "A",
		scope: { reply: "=" },
		templateUrl: "/assets/chats/func/reply.html"

	#display single chat messges at chats/chat_list.html, chats/show.html
	app.directive "msg", () ->
		restrict: "A",
		scope: { msg: "=", read: "="},
		templateUrl: "/assets/chats/func/message.html"

	# /template/search/search.html
	app.directive "userSearch", () ->
		restrict: "E",
		controller: "usersCtrl", controllerAs: "users",
		templateUrl: "/assets/search/func/user_search.html"

	# /template/users/func/user_fields.html for users#edit and users#new
	app.directive "matchWith", () ->
		restrict: "A",
		require: "?ngModel",
		link: (scope, elem, attrs, ngModel) ->
			return unless ngModel
			scope.$watch attrs.ngModel, () ->
				validate()
			attrs.$observe 'matchWith', () ->
				validate()

			validate = () ->
				input = ngModel.$viewValue
				other = attrs.matchWith
				ngModel.$setValidity('matched', input==other) if input? && other?
					
).call(this)