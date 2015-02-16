( () ->
	app = angular.module('app.content', ['ngCookies', 'ngRoute', \
	'app.factories'	])

	contentCtrl = app.controller("contentCtrl", ["Jsonp", "$scope", "$rootScope", "$route", "$location", "$anchorScroll", "$q", "$cookies", (Jsonp, $scope, $rootScope, $route, $location, $anchorScroll, $q, $cookies) ->
		content = this
		content.j = Jsonp
		content.formSubmit = false
		console.log "--------- contentCtrl.init"

		#content.j.vs.view.flash = {error: 'this is a error msg', info: "this is info msg", success: "this is success message"}

		content.formatForm = (data) ->
			data.utf8 =  String.fromCharCode(0x2713);  # '&#x2713;'
			data.authenticity_token = content.j.vs.token
			console.log("content.formatForm():: data = ", data)
			data

		content.send = (event, config) ->
			console.log("----- content.send() :: config = ", config)
			content.j.request(config)

		#return url by replace current_user and main_id
		content.parse_link = (link, sub) ->
			if sub%2 == 1 # main_id subsitution
				link = link.replace(/##main_id##/g, content.j.vs.view.data.main.pack.id)
			if sub>1 # current_user_id subsitution
				link = link.replace(/##current_user_id##/g, content.j.vs.view.current_user.id)
			link
		#check form.$valid before calling content.send
		content.postForm = (event, url, data, formObj, method) ->
			event.preventDefault()
			name = "------  content.postForm"
			console.log(name+"  :: formObj = ", formObj)
			content.formSubmit = true
			if formObj.$valid
				data.utf8 =  String.fromCharCode(0x2713);  # '&#x2713;'
				data.authenticity_token = content.j.vs.token
				config = {method: method, url: url, data: data}
				console.log(name+" :: config = ", config)
				content.send(event, config)
			
		#return template url for every paginate types
		content.paginate_template = (type) ->
			switch type
				when "users" then "/assets/users/user_list.html"

				when "chats" then "/assets/chats/chat_list.html"
				when "posts" then "/assets/posts/post_list.html"
				when "messages" then "/assets/chats/message_list.html"
				when "tags" then "/assets/users/tag_list.html"

		content.paginated_total = () ->
			if content.j.vs.view.data.paginate? && content.j.vs.view.data.paginate.total > 1
				content.j.vs.view.data.paginate.total
			else
				0 # no page 

		content.paginate_scroll = (idx) ->
			tag = 'paginate_' + content.j.vs.view.data.paginate.ids[idx]
			console.log "---- content.paginate_scroll - goto id = " + tag
			current = $location.hash()
			$location.hash(tag)
			$anchorScroll();
			$location.hash(current)

		content.paginate_empty = (type) ->
			if content.j.vs.view.data.paginate? \
			&& content.j.vs.view.data.paginate.pack? \ 
			&& content.j.vs.view.data.paginate.pack.length > 0
				if type? and type.length > 0
					content.j.vs.view.data.paginate.type != type
				else
					false #no type, just check pack.length>0
			else
				true

		content.paginate_append = (new_page, new_data) ->
			
			if content.j.vs.view.data.paginate.loaded && content.j.vs.view.data.paginate.ids
				content.j.vs.view.data.paginate.loaded.push(new_page)
				content.j.vs.view.data.paginate.ids.push(new_data.pack[0].id)
			else
				content.j.vs.view.data.paginate.loaded = [content.j.vs.view.data.paginate.page, new_page]
				content.j.vs.view.data.paginate.ids = [content.j.vs.view.data.paginate.pack[0].id, new_data.pack[0].id ]
			if content.j.vs.view.data.paginate.page < new_page.page
				content.j.vs.view.data.paginate.pack = new_data.pack.concat(content.j.vs.view.data.paginate.pack)
			else
				content.j.vs.view.data.paginate.pack = content.j.vs.view.data.paginate.pack.concat(new_data.pack)
			content.j.vs.view.data.paginate.loading = false
			content.j.vs.view.data.paginate.page = new_page

		content.paginate_load = (page_no) ->
			paginate = content.j.vs.view.data.paginate
			content.j.vs.view.data.paginate.loading = true

			q = $q.defer()
			config = {method: "jsonp", url: paginate.path, params: {callback: "JSON_CALLBACK", page: page_no} }
			content.j.connects(q, config).then( (response) ->
				if response.data.data.paginate? &&  response.data.data.paginate.path? && \
				(response.data.data.paginate.path == content.j.vs.view.data.paginate.path) && (response.data.data.paginate.type == content.j.vs.view.data.paginate.type)
					content.paginate_append(page_no, response.data.data.paginate)
					#$scope.$apply()
				else #wrong paginate type - refresh entire page
					content.j.vs.set(response.data, $cookies["XSRF-TOKEN"])
			, (response) ->
				content.j.vs.view.data.paginate.loading = false
				content.j.vs.view.flash = {error: "Connection Error while accessing "+ paginate.path }
			)
			return q.promise

		content.paginate_page = (page) ->
			name = " ---- content.paginate_page"
			console.log(name+"("+page+")")
			paginate = content.j.vs.view.data.paginate
			if !paginate.loading && page>0 && page <= paginate.total
				paginate_old = paginate
				if paginate_old? && paginate_old.loaded?
					idx = paginate_old.loaded.indexOf(page)
					if idx > -1
						paginate.page = page
						content.paginate_scroll(idx)
					else
						content.paginate_load(page)
				else
					content.paginate_load(page)

		content.paginate_has_more = () ->
			if content.j.vs.view.data.paginate?
				content.j.vs.view.data.paginate.page < content.j.vs.view.data.paginate.total
			else
				false

		content.showValue = (prefix, field)	->
			if field? then (prefix + field) else "-----"

		content.relates = (code) ->
			switch code 
				when -1 then "Blocked"
				when 1 then "Request"
				when 2 then "Pending"
				when 3 then "Friended"
				when 4 then "Own"
				else "Stranger"

		content.demo = () ->
			#"demo"
			console.log "content.demo"
			content.j.vs.view.flash = {info: "called content.demo()", error: "called content.demo()", success: "called content.demo()"}
			content.j.vs.view.title = "Demo Title"

		content.refresh = () ->
			$scope.$apply()
		console.log "--------- contentCtrl.done"
		content

		content.highlight = (allows, type, text, pos) ->
			type = parseInt(type)
			if content.j.vs.view.data.main.pack.search? \
			&& content.j.vs.view.data.main.pack.search.term? \
			#&& content.j.vs.view.data.main.pack.search.term.length > 0 \
			&& allows.indexOf(type) > -1
				len = content.j.vs.view.data.main.pack.search.term.length
				pos = parseInt(pos)
				ends = pos + len
				text.slice(0,pos) + "<b>"+ text.slice(pos, ends) + "</b>" +text.slice(ends, text.length) 
			else
				text
	])

).call(this)