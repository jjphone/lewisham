module ChatsHelper
	
	def chat_html(page)
		case page 
		when 'new'
			assets("/chats/new.html")
		when 'show'
			assets("/chats/show.html")
		else
			assets("/chats/index.html")
		end		
	end

	def chats_to_view(talkers, flashs, link, title)
		json = talkers.map{ |t|
			if msg = t.chat.latest
				t.chat.to_h( {message: msg.to_h(nil), read: t.after?(t.chat.updated_at)} )
			else
				t.chat.to_h( {read: true} )
			end
		}
		@view = createView(link, chat_html("index"), site_title("Chats#{title}"), flashs)
		@view.paginates("chats", link, talkers, json)
	end

	def msg_to_view(chat, flashs, link, title)
		title = "Chat with #{chat.display}" unless title
		link = "/chats/#{chat.id}" unless link
		msg = chat.active_msg.paginate(page: params[:page])
		json = msg.map{ |m|
			m.to_h(nil)
		}
		@view = createView(link, chat_html('show'), title, flashs)
		@view.paginates("messages", link, msg, json)
		ids = chat.active_users.map{ |u|
			{id: u.id, tag: u.login, name: u.name, avatar: u.avatar.url }
		}
		#main = {chat: {id: chat.id, owner: chat.user_id}, ids: ids, modify: false }
		# @view.main = main
		
		@view.main = {type: "chat", ids: ids, modify: false, pack:{id: chat.id, owner: chat.user_id}}
	end

	def list_chats(type, user_id, flashs)
		case type
		when 'unread'
			key = 'chats#index#unread'
			chats = Talker.unread_chats_link_to(user_id).paginate(page:params[:page])
			link = "/chats?type=unread"
			title = " - Unread"
		when 'own'
			key = 'chats#index#own'
			chats = Talker.own_chats_link_to(user_id).paginate(page:params[:page])
			link = "/chats?type=own"
			title = " - Own"
		else
			key = 'chats#index#all'
			chats = Talker.chats_link_to(user_id).paginate(page:params[:page])
			link = "/chats?type=all"
			title = ""
		end
		link = link + "&page=#{params[:page].to_i.to_s}" if params[:page]
		chats_to_view(chats, flashs, link, title)
		gen_links( get_links("level", key), chats_links )
	end


	def show_chats(id, flashs)
		chat = Chat.find_by( id: id )
		messages = Message.where(chat_id: id).includes(:user).paginate(page: params[:page])
		json = messages.map{ |m|
			m.to_h nil
		}
		path = "/chats/#{id}"
		@view = createView(path, chat_html("show"), site_title("Chat##{id}"), flashs )
		@view.paginates("messages", path, messages, json)
		@view.main = {type: "chat", id:id, user_id: chat.user_id, ids: Talker.user_tags_on_chat(chat_id) }
	end

	def chats_links
		get_links("related", "chats")
	end
end
