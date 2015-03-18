class MessagesController < ApplicationController
	include ChatsHelper
	before_action :signed_in_user

	# mark messages in chat as read
	def update
		t = Talker.find_by({user_id: current_user.id, chat_id: params[:chat]})
		if t 
			flashs = nil
			t.touch
		else
			flashs = {error: "cant find chat id = #{params[:chat].to_i} within current user"}
		end
		list_chats(params[:type], current_user.id, flashs)
		renderViewWithURL(4, nil)
	end

	# delete message
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
