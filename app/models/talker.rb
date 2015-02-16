class Talker < ActiveRecord::Base
  belongs_to :user
  belongs_to :chat
  has_many :messages, primary_key: "chat_id", foreign_key: "chat_id"

  validates :user_id,   presence: true
  validates :chat_id,   presence: true
  self.per_page = 8

  def new_messages
    messages.where!("messages.updated_at > ?", self.updated_at);
  end

  # change active to nil
  def deactive
    update(active: nil)
    Message.where(user_id: self.user_id, chat_id: self.chat_id).update_all(active: nil)
    self.chat.update_last_message nil
    true
  end

  def after?(last_update)
    updated_at > last_update
  end

  def self.chats_link_to(user_id)
    Talker.where(user_id: user_id, active: 1).includes(chat: [latest: [:user]]);
  end

  def self.unread_chats_link_to(user_id)
    Talker.chats_link_to(user_id).where("talkers.updated_at < chats.updated_at").references(:chat);
  end

  def self.own_chats_link_to(user_id)
    Talker.chats_link_to(user_id).where(chats: {user_id: current_user.id});
  end

end
