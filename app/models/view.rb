class View
	include ActiveModel::Model
	attr_accessor :source, :site_url, :title, :path, :flash, :current_user, :template, :data, :syn_url, :done

	# View.new( Hash::obj )
	def initialize(obj)
		self.path = obj[:path]
		self.flash = obj[:flash]
		self.current_user = obj[:current_user]
		self.template = obj[:template]
		self.title = obj[:title]

		self.done = false
		self.syn_url = false
		self.data = {main: nil, paginate: nil, links: nil}

	end

	# view.data.main = Hash::obj
	def main=(obj)
		h = {main: obj}
		self.data.merge! h
	end

	# view.data.links.related = Hash::relates
	def relative_links=(relates)
		h = {links: {related: relates} }
		self.data.merge! h
	end

	# view.data.links.level = Hash::levels
	def level_links=(levels)
		h = {links: {level: levels} }
		self.data.merge! h
	end

	# view.path[current, prev] = (String::current,String::prev )
	def locations=(current, prev)
		self.path[:current] = current
		self.path[:prev] = prev if prev
	end

	# view.data.paginate = (String::type, String::path, Will_Paginate::paginate_obj, Hash::json_hash)
	def paginates(type, path, obj, json_hash)
		Rails.logger.debug "View.paginates : path = " + path
		p = {type: type, page: obj.current_page.to_i, total: obj.total_pages, path: path, loading: false, pack: nil}
		p[:pack] = json_hash if obj.size > 0
		self.data.merge!( {paginate: p} )
	end

	def persisted?
		false
	end
end
