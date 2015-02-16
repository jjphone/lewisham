class Menu < ActiveRecord::Base
	belongs_to :link
	default_scope -> { order(:order) }

	def link_h
		link.to_h
	end
end
