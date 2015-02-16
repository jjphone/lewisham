class User < ActiveRecord::Base
	include Sqlquery
	
	has_many :posts, 			dependent: :destroy
	has_many :relations, 		dependent: :destroy, foreign_key: "user_id"
	has_many :ties, dependent: :destroy, class_name: "Relation", foreign_key: "friend_id"
	has_many :others, 			through: :relations, source: :friend

	has_many :talkers, 			dependent: :destroy
	has_many :chats,			through: :talkers, source: :chat

	has_attached_file :avatar, :styles => { :medium => "150x150", :thumb => "50x50#" }, 
                      :default_url => "/assets/avatar.png",
                      :path => ":rails_root/public/images/:id/:style.:extension",
                      :url =>  "/images/:id/:style.:extension"

	before_save   { 
		self.email.downcase!
		self.name.capitalize!
	}
  
	before_create :create_remember_token
	
	before_validation {
		self.login = self.login.downcase.parameterize if self.login
	}

	has_secure_password

	self.per_page = 8

	# validations #
	email_regex =   /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
	phone_regex =   /\A[+|-]*\d+\z/i
	login_regex =   /\A[a-z][a-z0-9]*(-){1}[a-z0-9]+\z/i

	validates :name, 	presence:		true,	
						length:			{ within: 6...50 }

	validates :email,	presence:		true,
						length:			{ within: 6...100},
						format:			{ with: email_regex },	
						uniqueness:		{ case_sensitive: false }


	validates :login, 	presence:		true,
						length: 		{ within: 6...50},
						uniqueness:		{ case_sensitive: false},
						format:			{ with: login_regex }

	validates :phone, 	uniqueness:		{ case_sensitive: false },
						format:			{ with: phone_regex },
						length:			{ within: 6...20}

	validates_attachment :avatar, 	content_type: {content_type: /^image\/(gif|jpeg|jpg)/, 
											message: '(gif, jpg or jpeg) image format only' },
  									size: { in: 0..500.kilobytes, message: 'file size must < 500kb' }

	validates :password, length:          { within: 6...50}, if: :password

	after_validation { self.errors.messages.delete(:password_digest) }

	ADMIN	= 6
	ALIAS 	= 5
	OWN 	= 4
	FRIEND 	= 3
	PENDING	= 2
	REQUEST	= 1
	STRANGER = 0
	BLOCKED	= -1
	LIMITED = -2
	ALLOWED = -5

	# returns a hash obj of current User obj
	def to_h(extra, level)
		if authorize?(level)
			{ id: id, name: name, login: login, email: email, phone: phone, avatar_url: avatar.url, extra: extra}
		else
			{ id: id, name: name, login: login,  avatar_url: avatar.url, extra: extra}
		end
	end

	# returns a hash obj for View.data.main
	def to_view_main_h(extra, level)
		{type: "user", pack: self.to_h(extra, level) }
	end

	# returns a hash obj for current obj.errors.messages
	def errors_h
		{errors: self.errors.messages}
	end

	# returns either user path on user.id (/users/1234) or user.login  (/users/login_name)
	def to_slug
		# login ?	"/u/#{login}" : "/users/#{id}"
		"/users/#{id}"
	end

	# return list of users that has a relation with owner, with given string::condition 
	def self.includes_tie(owner, condition)
		Rails.logger.debug("----- includes_tie( #{owner} , #{condition} ) ------")
		User.includes(:ties).where!(relations: {user_id: [owner, nil]}).where!(condition);
	end

	# create new non-exists remember token for user cookies
	def User.new_remember_token
		begin 
			remember_token = SecureRandom.urlsafe_base64
		end while User.exists?( remember_token: User.digest(remember_token) )
		remember_token
	end

	# search user's ids with given relation type, by db_prod search_user_ids
	def search_for(term, phone, email, type)
		relation = [-1, 1, 2, 3].include?(type) ? type : nil
		sql = "select id from search_user_ids(?, ?, ?, ?, ?, #{self.class.per_page})"
		ids = User.find_by_sql([sql, self.id, term, phone, email, relation ]).map(&:id)
		# if ids.size && ids.size>0
		# 	User.where("id in (?)", ids);
		# else
		# 	User.none
		# end
	end

	# search_user_tag( "term", "1,2,3")
	def search_user_tag(term, avoid)
		term.gsub!(/\W/, '')
		added = avoid ? avoid.split(",").map(&:to_i) + [self.id] : [self.id]
		exclusion = Relation.where({status: -1, user_id: id}).pluck(:friend_id) + added
		Rails.logger.debug("------ User:::search_user_tag exclusion = [" + exclusion.to_s+ "]")
		sql = "select id, name, tag, type, pos from search_user_tag(?, ?, ?, #{self.class.per_page} )"
		res = run_sql([sql, self.id, term, exclusion.join(',') ])
		res.map(&:symbolize_keys)
	end


	def User.digest(token)
		Digest::SHA1.hexdigest(token.to_s)
	end

	# returns relation int::status of the other_id, by the current obj
	def related_to(other_id)
		return {relates: 4}  if other_id == self.id
		if r = Relation.relates(self.id, other_id)
			if r.alias_name
				{relates: r.status, nick: r.alias_name}
			else
				{relates: r.status}
			end
		else
			{relates: 0}
		end
	end

	#Update/create relations with the other user by other_id.
	def set_relation_with(other_id, action, nick)
		return OWN if other_id == id
		#cant use find_or_create_by, final status unknown
		relation = Relation.new(user_id: id, friend_id: other_id) unless relation = Relation.relates(id, other_id)
		case action
		when ALIAS
			relation.set_alias(nick)
		when FRIEND
			relation.accepts(nick)
		when REQUEST
			relation.request(nick)
		when STRANGER
			relation.unfriend
		when BLOCKED
			relation.block(nick)
		end
	end


private
	# implement paginate page for SQL
	def self.skip_rows(page)
		skip = page && page > 1 ? (page-1) * self.class.per_page : 0
	end

	def authorize?(level)
		[ADMIN, OWN, FRIEND, ALLOWED].include? level
	end

	def create_remember_token
		self.remember_token = User.digest(User.new_remember_token)
	end

end