class SearchController < ApplicationController
  include UsersHelper
  before_action :signed_in_user

  def index
    Rails.logger.debug( " ----- SearchController::index request.original_fullpath = " + request.original_fullpath )
    path = request.original_fullpath
    flashs = nil

    if params[:type] == "tags" && params[:term].size>0
      type = "tags"
      if params[:avoid] && params[:avoid].size > 0
        form_inputs = search_tags(params[:term] , params[:avoid])
      else
        form_inputs = search_tags(params[:term] , nil)
      end
    else
      case params[:type]
      when "users"
        Rails.logger.debug("----- serach user")
        type = "users"
        ids = current_user.search_for(params[:term], params[:phone], params[:email], nil)
        form_inputs = data_main( {type: 'users', term: params[:term], phone: params[:phone], email: params[:email]})
      when "id"
        Rails.logger.debug("----- serach id")
        type = "id"
        ids = params[:id].to_i
        form_inputs = data_main nil
      else
        Rails.logger.debug("----- serach else")
        flashs = {error: "Invalid search type"}
        ids = []
        form_inputs = data_main nil
      end
      res = User.includes_tie(current_user.id, ["users.id in (?)", ids] ).paginate(page: 1)
      list_users(path, search_html, res, path, flashs)
    end

    set_view_links(type)
    @view.main = form_inputs
    renderViewWithURL(4,nil)
  end
  
private
  def search_html
    assets("/users/index.html")
  end

  def set_view_links(type)
    level = case type
    when "tags"
      get_links("level", "search#tags")
    when "users"
      get_links("level", "search#users")
    else
      get_links("level", "search#else")
    end
    gen_links( level, get_links("related", "search") )
  end

  def search_tags(term, avoid)
    Rails.logger.debug("------ SearchController:::search_tags(#{term}, #{avoid})")
    # e.g /search?type=tags&term=user&avoid=1,2,3
    path = "/search?type=tags&term=#{term}&avoid=#{avoid}"
    res = current_user.search_user_tag(term, avoid)
    @view = createView(path, search_html, site_title('Tags'), nil)
    single_page("tags", path, res, nil )
    data_main( {type: "tags", term: term, avoid: avoid} )
  end

  def search_users(term, phone, email, relation_type)
    res = current_user.search_for(term, phone, email, relation_type)
  end

  # Fill in the @view.data.paginate on single page
  # @view.data.paginate = {type, page:1, total:1, path, loading:false, pack: data}
  def single_page(type, path, data, extra)
    return unless @view
    paginate = {type: type, page: 1, total:1, path: path, loading: false, pack: data}
    paginate.merge!(extra) if extra
    @view.data.merge!({paginate: paginate})
  end

  # => @view.data.main = {type: 'search', pack}
  def data_main(search_hash)
    {type: "search", pack: {search: search_hash} }
  end



end
