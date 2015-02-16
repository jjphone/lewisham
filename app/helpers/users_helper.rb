module UsersHelper
	RELATIONS = {-1 =>'block', 0 =>'stranger', 1 =>'request', 2 =>'pending', 3 =>'friend', 4 =>'own'}

	def user_html(page)
		case page 
		when 'new'
			assets("/users/new.html")
		when 'show'
			assets("/users/show.html")
		when 'edit'
			assets("/users/edit.html")
		else
			assets("/users/index.html")
		end
	end

	# convert @user into View object
	def user_show(url, flashs)
		relation = current_user.related_to(@user.id)
		@view = createView(url, user_html("show"), site_title(@user.name), flashs)
		@view.main = @user.to_view_main_h( relation , relation[:relates] )

		gen_links(	get_links('level', "relations##{RELATIONS[relation[:relates]]}" ), \
					get_links("related", "users") )

		posts = @user.posts.paginate(page: params[:page] )
		posts_json = posts.map{ |p| p.to_h(@user.name, @user.avatar.url) }
		@view.paginates("posts", url, posts, posts_json )
		@view
	end

	# convert the users.paginate into View object
	def list_users(url, page, users, paginate_url, msg)
		@view = createView(url, page, "Trainbuddy | Users", msg)
		json = users.map{ |u|
			if u.ties.first
				u.to_h( {relates: u.ties.first.status, nick: u.ties.first.alias_name }, u.ties.first.status )
			else
				u.to_h(nil, 0)
			end
		}
		@view.paginates("users", paginate_url, users, json )
		gen_links(	get_links("level", "users#index"), \
		 			get_links("related", "users") )
		@view
	end

	def user_list_page(flashs)
		users = User.includes_tie(current_user.id, ["users.id <> ?", current_user.id] ).paginate(page: 1)
		list_users("/users", user_html("index"), users, "/users", nil )
		renderViewWithURL(4,nil)
	end
end


