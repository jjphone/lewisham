class ApplicationController < ActionController::Base
	# Prevent CSRF attacks by raising an exception.
	# For APIs, you may want to use :null_session instead.
	protect_from_forgery with: :exception
	require 'rack/utils'

	#protect_from_forgery with: :null_session


	def redirect_format(url, message, callback)
		respond_to do |format|
			format.json {
				url = callback.to_s[/angular\.callbacks/i] ? jsonp_url(url, callback) : add_params(url, {redirect: true})
				Rails.logger.debug "----- redirect_format.json : url = #{url}"
				redirect_to(url, format: :json, flash: message, status: 303)
			}
			format.any {
				url = remove_param(url, "callback")
				redirect_to(url, format: :html, flash: message )
			}
		end
	end

	# append callback=angular.callbacks._<seq> to the url 
	def jsonp_url(url, callback)
		seq = callback ? callback[/\d+/].to_i : 0
		add_params(url, {callback: "angular.callbacks._#{seq}", redirect: true} )
	end

	def add_params(url, set)
		link = URI url
		if link.query
			params = Rack::Utils.parse_nested_query(link.query)
			set.each_key{ |k| params.delete(k) }
			link.query = set.merge(params).to_query
		else
			link.query = set.to_query
		end
		link.to_s
	end

	def remove_param(url, name)
		link = URI url
		if link.query 
			params = Rack::Utils.parse_nested_query(link.query)
			params.delete(name)
			link.query = (params.size > 0 ) ? params.to_query : nil
		end
		link.to_s
	end

	def angular_callback(query)
		callback = query[/callback=angular\.callbacks._\d+/]
		return callback ? callback[/\d+/].to_i : nil
	end

	def redirect_back_or(default, message)
		link = session[:return_to] || default
		session.delete(:return_to)
		redirect_format(link, nil, params[:callback])
	end


	def createView(url, page, title, flash)
		paths = { prev: remove_param(request.env["HTTP_REFERER"].to_s, "callback"), current: remove_param(url, "callback") }
		user = current_user ? current_user.to_h(nil, 4) : nil
		View.new( {path: paths, flash: flash, current_user: user, template: page, title: title} )
	end


	def renderViewWithURL(syncLevel, file)
		# syncLevel = 0 - dont care
		# syncLevel = 1 - update json
		# syncLevel = 2 - js + json
		# syncLevel = 4 - all
		flash.clear
		respond_to do |format|
			caller = [controller_name,action_name].join("#")
			format.json {
				@view.source = "json"
				if syncLevel > 0 || params[:redirect]
					@view.syn_url = true
					@view.path[:current] = remove_param( @view.path[:current], "redirect" )
				end
				set_csrf_cookie_for_ng
				render json: @view, content_type: 'application/javascript' , callback: params[:callback]
			}
			format.js {
				@view.source = "js"
				@view.syn_url = true if syncLevel > 1
				render file if file
			}
			format.html {
				@view.source = "html"
				@view.syn_url = true if syncLevel > 3
				render '/layouts/default' 
			}
		end
	end

	# return array of menu links
	def get_links(group, key)
		items = Menu.where(group: group, key: key).includes(:link)
		items.map(&:link_h)
	end

	def gen_links(level, related)
		@view.data.merge!({links: {level: level, related: related} })
	end

	def renderView
		renderViewWithURL(0, nil)
	end

	def set_csrf_cookie_for_ng
		cookies['XSRF-TOKEN'] = form_authenticity_token if protect_against_forgery?
	end	


	def verified_request?
		# Rails.logger.debug("----- verified_request " + request.headers['X_XSRF_TOKEN'].to_s)
		super || form_authenticity_token == request.headers['X_XSRF_TOKEN']
	end
	
	# Helper function. Append assets path before the file
	def assets(file)
		"/assets" + file
	end

	# Helper function. Append "Trainbuddy | " before append
	def site_title(append)
		"Trainbuddy | #{append}"
	end

	###  sesssion helpers ###

	
	def signed_in_user
		unless signed_in?
			store_location request.url
			redirect_format(signin_url, {info: "Required login"}, params[:callback] )
		end
	end

	def sign_in(user)
		remember_token = User.new_remember_token
		cookies[:remember_token] = { value: remember_token, expires: 2.hours.from_now.utc }
		user.update_attribute(:remember_token, User.digest(remember_token) )
    	self.current_user = user
	end

	def sign_out 
		#update_attribute bypass password validation
		if current_user
			current_user.update_attribute(:remember_token, User.digest(User.new_remember_token) )
			cookies.delete(:remember_token)
			self.current_user = nil
		end
	end
	
	def signed_in?
		!current_user.nil?
	end

	def current_user=(user)
		@current_user = user
	end

	def current_user?(user)
		user == current_user
	end

	def current_user
		remember_token = User.digest(cookies[:remember_token])
		@current_user ||= User.find_by(remember_token: remember_token)
		@current_user
	end

	def store_location(link = nil)
		if link
			session[:return_to] = link 
		else
			session[:return_to] = request.url if request.get?
		end
		Rails.logger.debug "------  SessionsHelper#store_location :: session[:return_to] =  #{session[:return_to]}"
	end


	# returns:
	# => nil if authentiated
	# => @view with new URL if error
	def auth_user
		@user = User.find_by(id: params[:id] )
		if @user 
			if current_user? @user 
				@view = nil
			else	#show @user 
				flashs = { error: "Insufficient priviledge on @#{@user.login}" }
				user_show(@user.to_slug, flashs)
			end
		else
			flashs = { error: "Invalid user id : #{params[:id].to_i}" }
			redirect_format("/", flashs, params[:callback] )
		end
	end



end
