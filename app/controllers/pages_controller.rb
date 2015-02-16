class PagesController < ApplicationController
	def index
		msg = nil
		p = page_view params[:id]
		@view = createView(p[:loc], p[:html], p[t], nil)
		renderView
	end

private 
	def page_view(page = 'home')
		case page
		when 'about'
			{html: assets("/pages/about.html"), loc: "/about", t: site_title("About") }
		when 'help'
			{html: assets("/pages/help.html"), loc: "/help", t: site_title("Help") }
		when 'contact'
			{html: assets("/pages/contact.html"), loc: "/contact", t: site_title("Contact") }
		else
			{html: assets("/pages/home.html"), loc: "/", t: "Trainbuddy" }
		end
	end

end
