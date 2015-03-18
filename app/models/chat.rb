class Chat < ActiveRecord::Base
  has_many  :talkers
  has_many  :messages,  dependent: :destroy
  has_many  :users,   through: :talkers, source: :user
  belongs_to  :latest,  class_name: "Message", foreign_key: "last_message"

  self.per_page = 8
  default_scope -> { order('chats.updated_at DESC') }

  # returns the talker for the sender if message created
  def self.create_new(sender_id, ids, content, html)
    sender = User.find_by(id: sender_id)
    users = User.where("id in (?)", ids - blocked(sender.id) )
    return ["no users found", nil] if users.empty?
    c = Chat.create(user_id: sender.id)
    m = Message.create(user_id: sender.id, chat_id: c.id, content: content, html: html) if content
    users.each{ |u|
      Talker.create(user_id: u.id, chat_id: c.id)
    }
    c.update_attributes({last_message: m.id, display: display_names(sender.login, users)})
    Talker.create(user_id: sender.id, chat_id: c.id)
    [nil, c]
  end

  # add message on existing chat
  def add_msg(sender_id, content, html)    
    return ["no message created as content is blank"] unless content
    if talker = Talker.find_by(chat_id: id, user_id: sender_id)
      m = Message.create(user_id: sender_id, chat_id: id, content: content, html: html)
      update(last_message: m.id)
      talker.touch
      nil
    else
      ["unable to find user with id = #{sender_id.to_i} in chat"]
    end
  end
  
  # update chat group user list
  def update_users(from_id, ids)
    remove = Talker.where(chat_id: id).where(active: 1).where("talkers.user_id not in (?)", ids).pluck(:user_id)
    if remove.size > 0 && err =  remove_users(from_id, remove)
      return err
    end
    new_users(from_id,ids)
    update_names
    nil
  end


  def active_msg
    messages.where(active: 1).includes(:user);
  end

  # show only active users 
  def active_users
    ids = Talker.where(chat_id: self.id).where(active: 1).pluck(:user_id)
    User.where("id in (?)", ids)
  end


  # deactive chat if owner, otherwise deactive at talker level
  def deactive(user_id)
    if self.user_id == user_id
      values = {active: nil, updated_at: DateTime.now}
      self.update(values)
      Talker.where(chat_id: self.id).update_all(values)
      Message.where(chat_id: self.id).update_all(values)
      return [true, "Owner removed the chat group"]
    end
    
    if talker = Talker.find_by(chat_id: self.id, user_id: user_id, active: 1)
      [talker.deactive, "User quited chat"]
    else
      [false, "User is not in the chat with chat id = #{self.id}"]
    end
  end

  # return concate the list of talker.user.login
  def self.display_names(sender, users)
    list = users.map{ |t|
      "@" + t.login
    }.unshift("@#{sender}")
    list.join(',')
  end

  # returns chat_ids when user is part of the chat group
  def self.ids_with_user(user)
    sql = "select c.* from chats c, talkers t where t.user_id = #{user.to_i} and c.id = t.chat_id"
    Chat.connection.select_all(sql);
  end

  # returns a hash verison for json
  def to_h(extra)
    {id: id, user: user_id, display: display, extra: extra}
  end

  # udpate the last_message column with the latest active message
  def update_last_message(deactive)
    if deactive.nil? || last_message == deactive
      if msg = messages.where("active is not null").order(updated_at: :desc).limit(1)[0]
        update(last_message: msg.id)
      else
        update(last_message: nil)
      end
    end
  end



  # add new users to chat
  def new_users(from_id, ids)
    # existing users
    Talker.where("active is null and chat_id = (?) and user_id in (?)", self.id, ids).update_all({active: 1, updated_at: DateTime.now})

    # new users
    sql = "select users.id from users where id in (?) and id not in (select user_id from talkers where chat_id = ?)"
    add = User.find_by_sql([sql, ids, self.id]).map(&:id) - self.class.blocked(from_id)
    add.each{ |u|
      Talker.create(user_id: u, chat_id: self.id)
    }
  end

  def remove_users(from_id, ids)
    Rails.logger.debug("------ remove_users(#{from_id}, #{ids.to_s}) @ chat(#{id}).user = #{user_id} ")

    return ["can't delete chat owner. need to remove whole chat"] if ids.include?(self.user_id)
    if from_id == self.user_id || (ids.size == 1 && ids[0] == from_id)
      condition = ["chat_id = ? and user_id in (?)", self.id, ids]
      values = {active: nil, updated_at: DateTime.now }
      Talker.where(condition).update_all(values)
      Message.where(condition).update_all(values)
      nil
    else
      ["can't update other users unless chat owner"]
    end
  end

  def self.blocked(sender)
    Relation.where("status = -1 and friend_id = ?", sender).map(&:user_id).push(sender)
  end

  def update_names
    sender_login = User.find_by(id: self.user_id).login
    others = self.users.where("user_id != ?", self.user_id)
    self.class.display_names(sender_login, others)
  end
end
