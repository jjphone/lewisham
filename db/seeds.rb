sql = [
	'db/plpgsql_search_user_ids_on_any_relation.sql',
	'db/plpgsql_search_user_ids_on_relation.sql',
	'db/plpgsql_search_user_ids.sql',
	'db/plpgsql_search_user_tag.sql'
]
sql.each{ |file|
	puts "Running - #{file} : ---- "	
	res = ActiveRecord::Base.connection.execute(File.open(file, 'r').read)
  	puts "          #{file} is done !  ---- "
}

Link.destroy_all 
Link.create(display: "home", 	url: "/", 								method: 'get')
Link.create(display: "profile", url: "/users/##current_user_id##/edit", method: 'get', substitue: 2)
Link.create(display: "config",	url: "/config/##current_user_id##", 	method: 'get', substitue: 2)
Link.create(display: "map",		url: "/maps", 							method: 'get')

Link.create(display: "unfriend",url: "/relations/##main_id##?op=0", 	method: 'put', substitue: 3)
Link.create(display: "unblock", url: "/relations/##main_id##?op=-1", 	method: 'put', substitue: 3)
Link.create(display: "request",	url: "/relations/##main_id##?op=1", 	method: 'put', substitue: 3)
Link.create(display: "accept", 	url: "/relations/##main_id##?op=3", 	method: 'put', substitue: 3)
Link.create(display: "block", 	url: "/relations/##main_id##?op=-1", 	method: 'put', substitue: 3)

Link.create(display: "users", 	url: "/users", 							method: 'get')
Link.create(display: "friends", url: "/users?type=3", 					method: 'get')
Link.create(display: "pendings",url: "/users?type=2", 					method: 'get')
Link.create(display: "requested",url: "/users?type=1",	 				method: 'get')
Link.create(display: "blocked", url: "/users?type=-1", 					method: 'get')


Link.create(display: "chats", 		url: "/chats", 						method: 'get')
Link.create(display: "msg user", 	url: "/chats/new?user=##main_id##",	method: 'get', substitue: 1)

Link.create(display: "all chats",	url: "/chats?type=all", 			method: 'get')
Link.create(display: "unread", 		url: "/chats?type=unread", 			method: 'get')
Link.create(display: "own chat",	url: "/chats?type=own", 			method: 'get')

Link.create(display: "exit chat", 	url: "/chats/##main_id##", 			method: "delete", substitue: 1)
Link.create(display: "search", 		url: "/users", 						method: 'get')
Link.create(display: "new search", 	url: "/users", 						method: 'get')
p "Created #{Link.all.size} links"

def create_menu(group, key, names)
	names.to_a.each_with_index do |item, index|
	  Menu.create(group: group, key: key, order: index, link_id: Link.find_by(display: item).id )
	end
end


Menu.destroy_all
create_menu('related', 'users', ['home', 'chats', 'map'])
create_menu('related', 'chats', ['home', 'search', 'profile'])
create_menu('related', 'search',['home', 'chats', 'map', 'users'])

create_menu('level', 'users#index', ['users', 'friends', 'pendings', 'blocked', 'requested'])
create_menu('level', 'realtions#own', ['profile', 'config', 'msg user'])
create_menu('level', 'relations#friend', ['unfriend', 'block', 'msg user'])
create_menu('level', 'relations#pending', ['accept', 'block', 'msg user'] )
create_menu('level', 'relations#request', ['request', 'unfriend', 'block', 'msg user'] )
create_menu('level', 'relations#block', ['unblock', 'msg user'])
create_menu('level', 'relations#stranger', ['request', 'block', 'msg user'])

create_menu('level', 'search#users', ['new search', 'friends', 'pendings', 'requested'])
create_menu('level', 'search#tags',  ['new search', 'friends'])
create_menu('level', 'search#else', ['new search', 'friends'])

create_menu('level', 'chats#index#all', ['unread', 'own chat'])
create_menu('level', 'chats#index#unread', ['all chats', 'own chat'])
create_menu('level', 'chats#index#own', ['all chats', 'unread'])
create_menu('level', 'chats#show', ['exit chat'])

p "Created #{Menu.all.size} menu items"
