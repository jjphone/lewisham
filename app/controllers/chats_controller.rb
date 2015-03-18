class ChatsController < ApplicationController
	include ChatsHelper
	before_action :signed_in_user
	def index
		type =  params[:type] ? params[:type] : "all"
		list_all(type, nil)
	end

	def show
		if chat = current_user.chats.find_by(id: params[:id])
			show_chat(chat, nil)
		else
			list_all('all', {error: "can't find chat id = #{params[:id].to_i.to_s}"})
		end
	end

	def create
		res = Chat.create_new(current_user.id, params[:to], params[:content], nil)
		if res[1]
			show_chat(res[1], nil)
		else
			list_all("all", {error: res[0]})
		end
	end

	def update
		if chat = current_user.chats.find_by(id: params[:id])
			msg = nil
			flashs = nil
			if params[:modify] && err = chat.update_users(current_user.id, params[:to])
				msg = err[0]
			end
			if params[:content] && err = chat.add_msg(current_user.id, params[:content], nil)
				flashs = msg ? {error: "#{msg} and #{err[0]}"} : {error: err[0]}
			end
			show_chat(chat, flashs)
		else
			list_all('all', {error: "can't find chat id = #{params[:id].to_i.to_s}"})
		end
	end

	def destroy
		chat = Chat.find_by(id: params[:id])
		flashs = nil
		if chat
			flashs = {info: chat.deactive(current_user.id)[1]}
		else
			flash = {error: "Unable to find chat id = #{params[:id].to_i.to_s} on current user"}
		end
		list_all(params[:type], flashs)
	end

private
	def list_all(type, flashs)

		list_chats(type, current_user.id, flashs)
		renderViewWithURL(4,nil)
	end

	def show_chat(chat, flashs)
		msg_to_view(chat, flashs, nil, nil)
		gen_links( get_links("level", "chats#show" ), chats_links)
		renderViewWithURL(4,nil)
	end
end
