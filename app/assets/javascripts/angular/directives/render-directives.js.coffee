( () ->
	# side menus : paginate, level, related
	app = angular.module('app.renderDirectives', [])

	app.directive "sideMenu", () ->
		restrict: "E",
		templateUrl: "/assets/layouts/menu.html"
	app.directive "menuPaginates", () ->
		restrict: "A",
		templateUrl: "/assets/layouts/paginates.html"
	app.directive "menuLevels", () ->
		restrict: "A",
		templateUrl: "/assets/layouts/levels.html"
	app.directive "menuRelated", () ->
		restrict: "A",
		templateUrl: "/assets/layouts/related.html"
	app.directive "link", () ->
		restrict: "A",
		templateUrl: "/assets/layouts/link.html"

	# list paginate items
	app.directive "pagination", () ->
		restrict: "A",
		templateUrl: "/assets/layouts/pagination.html"

	# list no record for pagination
	app.directive "paginateEmpty", () ->
		restrict: "A",
		templateUrl: "/assets/layouts/no_record.html"

	# /template/sessions/new.html
	app.directive "sessionLogin", () ->
		restrict: "E",
		templateUrl: "/assets/sessions/func/login.html"

	# /template/users/show.html for user-info.span2
	app.directive "userInfo", () ->
		restrict: "A",
		templateUrl: "/assets/users/func/user_info.html"

	# display individual post for users#show and signined.home page
	app.directive "postItem", () ->
		restrict: "A",
		templateUrl: "/assets/posts/post.html"

	# display user name and avatar in posts/users
	app.directive "userTitle", () ->
		restrict: "AC",
		scope: {avatar: "@", name: "@" },
		templateUrl: "/assets/users/func/user_title.html"
	# display user form fields at users/edit.html, users/new.html
	app.directive "userFields", () ->
		restrict: "A"
		templateUrl: "/assets/users/func/user_fields.html"


		
).call(this)