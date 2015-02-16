( () ->
	app = angular.module('app.users', ['ngRoute', \
	'app.factories'	])

	usersCtrl = app.controller("usersCtrl", ["Jsonp", "$scope", "$rootScope", "$location",  (Jsonp, $scope, $rootScope, $location) -> 
		users = this
		users.j = Jsonp
		users.search = {}
		unless (users.j.vs.view.data.main? and users.j.vs.view.data.main.pack?)
			users.j.vs.view.data.main = {type:"search", pack: { search: {type: "users"} } }

		users.formChecked = false

		users.user_paths = (id, action) ->
			switch action
				when "edit" then '/users/'+id+"/edit"
				when "new" then "/signup"
				when "index" then "/users"
				when "create" then "/users"
				else "/users/"+id

		# check given form and field is valid
		users.errorField = (form, field, errorType) ->
			#console.log("----- users.validField :: form = ", form)
			if errorType
				users.formChecked && form[field].$error && form[field].$error[errorType]
			else
				users.formChecked && form[field].$error


		users.errorMsg = (fName) ->
			if users.j.vs.view.data.main.pack.extra && users.j.vs.view.data.main.pack.extra.errors && users.j.vs.view.data.main.pack.extra.errors[fName]
				users.j.vs.view.data.main.pack.extra.errors[fname]
			else
				false

		#convert search form data into http.get request with params as data.fi
		users.searchForm = (event, url, data, form) ->
			event.preventDefault()
			name ="----- users.searchForm()"
			console.log(name+" :: form = ", form)
			console.log(name+" :: data = ", data)

			if form.$invalid
				users.formChecked = true
				console.log(name+" :: form.$invalid")
			else #sending GET request
				config = {method: 'get', url: url, params: data }
				users.formChecked = false
				users.j.request(config)
				console.log(name+" :: form.$valid")
			false
			

		users.submitForm = (event, url, form, method) ->
			event.preventDefault()
			name ="----- users.submitForm()"
			console.log name
			u = users.j.vs.view.data.main.pack
			if form.$invalid
				console.log(name+" :: form.$invalid")
				u.extra.errors = {} if u.extra && u.extra.errors
				users.j.vs.view.flash = {}
				users.formChecked = true
			else
				fd = new FormData()
				fd.append("user[term]", u.term) 
				fd.append("user[email]", u.email)
				fd.append("user[phone]", u.phone )
				fd.append("user[login]", u.login)
				if users.j.vs.view.data.password? # password already match with confirmation
					fd.append("user[password]", users.j.vs.view.data.password )
					fd.append("user[password_confirmation]", users.j.vs.view.data.password_confirmation)
				fd.append("user[avatar]", users.j.vs.view.data.files[0] ) if users.j.vs.view.data.files? && users.j.vs.view.data.files.length>0

				console.log(name + " : FormData() -> fd = ", fd)
				config = {method: method, url: url, data: fd, headers: {'Content-Type': undefined}, transformRequest: angular.identity }
				users.j.request(config)
				users.formChecked = false
			false

			console.log(name+" :: done ")
			event.preventDefault()
			false

		console.log "----- usersCtrl.done"
		users
	])
	sessionsCtrl = app.controller("sessionsCtrl", () -> 
		sessions = this
		sessions.data = {}
		console.log "--------- sessionsCtrl.done"
		sessions
	)
).call(this)