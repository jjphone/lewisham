( () ->
	app = angular.module('app.chats', ['app.factories'])
	chatsCtrl = app.controller("chatsCtrl", ["Jsonp", "$q", (Jsonp, $q) ->
		chats = this
		chats.j = Jsonp

		#chats.formFields()

		# overwrite the request response when type = 'tags'
		# for /search?type=tags&term=user_input
		chats.userLookup = (type) ->
			if chats.j.vs.view.data.main.talkers? && chats.j.vs.view.data.main.talkers.length > 0
				params = {callback: "JSON_CALLBACK", type: 'tags', \
				term: chats.j.vs.view.data.main.talkers, \
				avoid: chats.ids_to_s(chats.j.vs.view.data.main.ids).toString() }

				config = {method: 'jsonp', url: '/search', params: params}
				q = $q.defer()
				chats.j.connects(q, config).then( (res) ->
					console.log("---- chats.userLookup:: res.data=", res.data)
					if res.data.data? && res.data.data.paginate.type == type
						chats.usersHints(res.data.data)
					else
						chats.j.vs.updateView(res)
				, (res) ->
					q.reject("Error: /search.jsonp error")
				)
			else
				chats.clearLookup()	

		chats.clearLookup = () ->
			chats.j.vs.view.data.main.talkers = null
			chats.j.vs.view.data.main.type = null

		chats.formFields = () ->
			unless chats.j.vs.view.data.main?
				chats.j.vs.view.data.main = {pack: null, type: "search"}
			unless chats.j.vs.view.data.main.pack?
				chats.j.vs.view.data.main.pack = {search: null }
			unless chats.j.vs.view.data.main.pack.search?
				chats.j.vs.view.data.main.pack.search = {type: 'tags', avoid: null, term: null}

		
		# convert user tag search result from (view.data) to view.data.main,
		# without overwrite existing view.data.paginate during displaying chat messages.
		# view.data.main.pack.search => view.data.main.pack.search
		# view.data.paginate.pack => view.data.main.pack.search.pack 
		chats.usersHints = (data) -> 
			chats.j.vs.view.data.main.type = 'tags'
			chats.j.vs.view.data.main.pack = data.main.pack
			chats.j.vs.view.data.main.pack.search.pack = data.paginate.pack

		# list = [{id,tag}, ... ]
		chats.ids_to_s	= (list) ->
			if list? then (user.id for user in list) else []
		
		# add user to view.data.main.ids
		chats.addUser = (user) ->
			#look for user info
			u = {id: user.id, tag: user.tag, name: user.name}
			console.log("----- chats.addUser user : ", user)
			params = {callback: "JSON_CALLBACK", type: 'id', id: user.id}
			config = {method: 'jsonp', url: '/search', params: params}
			q = $q.defer()
			# discard error - no user image
			Jsonp.connects(q, config).then( (res) ->
				console.log("---- chats.addUser:: res.data = ", res.data)
				if res.data.data.paginate? && res.data.data.paginate.total == 1 
					u.avatar = res.data.data.paginate.pack[0].avatar_url
					u.cache = true
			)

			if chats.j.vs.view.data.main.ids? && chats.j.vs.view.data.main.ids.length > 0
				chats.j.vs.view.data.main.ids.push(u)
			else
				chats.j.vs.view.data.main.ids = [u]
			chats.ids_modified()	
			chats.clearLookup()

		# update view.data.main.modify = true when to_ids has updated
		chats.ids_modified = () ->
			console.log "------   chats.ids_modified() "
			Jsonp.vs.view.data.main.modify = true if Jsonp.vs.view.data.main?

		# remove user  at index from view.data.main.ids
		chats.removeUser = (index) ->
			console.log("removeUser("+index+")")
			if Jsonp.vs.view.data.main.ids? && Jsonp.vs.view.data.main.ids.length > index
				if !Jsonp.vs.view.data.main.chat? \  #new msg
				|| chats.ownChat(Jsonp.vs.view.data.main.chat.owner) \ # chat owner
				|| chats.ownChat(Jsonp.vs.view.data.main.ids[index].id ) # delete self
					Jsonp.vs.view.flash = null
					chats.ids_modified()
					Jsonp.vs.view.data.main.ids.splice(index,1)
				else
					Jsonp.vs.view.flash = {error: "can't remove others unless chat owner"}

		chats.sendMsg = (event, url, form, method) ->
			event.preventDefault()
			unless form.$invalid
				data = { utf8: String.fromCharCode(0x2713),	authenticity_token: Jsonp.vs.token,
				to: chats.ids_to_s(Jsonp.vs.view.data.main.ids),
				content: Jsonp.vs.view.data.main.message,
				modify: Jsonp.vs.view.data.main.modify
				}
				# for reply existing chats
				data.chat_id = Jsonp.vs.view.data.main.chat.id if Jsonp.vs.view.data.main.chat?
				console.log("data = ", data)
				config = {url: url, method: method, data: data}
				Jsonp.request config

		#extract chat list type from paginate path
		chats.listType = (path) ->
			type =  path.match(/(\?|&)type=(\w)+/g)
			if type then type.slice(6) else	'all'

		#send messages#update?type=paginate_type
		chats.markRead = (chat_id, msg_id) ->
			url = '/messages/'+msg_id
			data = {type: chats.listType(chats.j.vs.view.data.paginate.path), chat: chat_id }
			config = {method: 'patch', url: url, params: data}
			chats.j.request(config)


		# append source list type into show url
		chats.list_path = (chat_id) ->
			"/chats/" + chat_id + "?type="+chats.listType(chats.j.vs.view.data.paginate.path)

		chats.ownChat = (owner_id) ->
			chats.j.vs.view.current_user.id == owner_id

		chats.kickUser = (chat_id, user_id) ->
			1


		console.log "--------- chatsCtrl.done"
		chats
	])

).call(this)