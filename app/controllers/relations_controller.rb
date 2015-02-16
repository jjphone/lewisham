class RelationsController < ApplicationController
	include UsersHelper
	before_action :signed_in_user

	def update
		Rails.logger.debug "------ relations#update"
		@user = User.find_by_id( params[:id] )
		if @user
			if current_user.set_relation_with(@user.id, params[:op].to_i, params[:nick])
				flashs = {success: "Relation updated."}
			else
				flashs = {error: "Unable to update the relation."}
			end
			user_show(@user.to_slug, flashs)
			renderViewWithURL(4,nil)
		else
			flashs = { error: "Invalid user id : #{params[:id].to_i}"}
			user_list_page(flashs)
		end
	end
end
