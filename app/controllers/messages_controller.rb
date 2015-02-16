class MessagesController < ApplicationController
	include ChatsHelper
	before_action :signed_in_user

	def update
		t = Talker.find_by( {user_id: current_user.id, chat_id: params[:chat]} )
		t.touch if t
		list_chats(params[:type], current_user.id, nil)
		renderViewWithURL(4, nil)
	end

	def destroy
		msg = Message.find_by(id: params[:id], user_id: current_user.id)
		if msg
			flashs = nil
			msg.deactive
		else
			flashs = {error: "can't find msg id = #{params[:id].to_i.to_s} in user messages"}
		end
		list_chats('all', current_user.id, flashs)
		renderViewWithURL(4,nil)
	end

end
