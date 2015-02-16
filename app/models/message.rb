class Message < ActiveRecord::Base
	belongs_to :user
	belongs_to :chat

	
	default_scope -> { order('created_at DESC') }
	self.per_page = 8

	validates	:user_id, 	presence: true
	validates	:chat_id, 	presence: true

	
	def delete
		self.active = nil
	end

	def reply(content, extra)
	end

	def to_h(extra)
		{id: id, user: user_id, login: user.login, avatar: user.avatar.url, active: active, content: content, html: html, extra: extra, updated_at: updated_at_in_words}
	end
	
	def updated_at_in_words
		syd_time = updated_at.in_time_zone("Sydney")
		syd_time.today? ? syd_time.strftime("%I:%M %P") : syd_time.strftime("%m.%d %H:%M")
	end

	def deactive
		update(active: nil)
		self.chat.update_last_message(self.id)
	end

end
