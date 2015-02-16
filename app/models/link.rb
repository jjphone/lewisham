class Link < ActiveRecord::Base
	# Store Link as an object for re-use. 
	#
	# display: 	Display Text on page 
	# => <a> __display__</a>
	#
	# method: 	Methods of the http request (mainly for AngularJS). [get, put, patch, json, delete]
	# => /layouts/links.html::  <a .... ng-method=__method__ >
	# 	
	# url: 		Url of the link. 
	# => <a ng-href=___URL___>
	#
	# substitue: Substituations for link variables. supported ONLY. 
	# => ##main_id## 		= params[:id] (viewService.js) -> view.data.main.id
	# => ##current_user## 	= current_user.id  (viewService.js) -> view.current_user.id

	def to_h
		{name: display, url: url, method: method, sub: substitue}
	end
end
