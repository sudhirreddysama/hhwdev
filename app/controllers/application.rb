# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  #protect_from_forgery # :secret => 'a80f975e77adafb1085da89eda90b0ed'
  filter_parameter_logging :password

	include ExceptionNotifiable

	def require_perm_admin
		return false unless authorize and @current_user.admin_level >= 2
	end
	
	def require_perm_subadmin
		return false unless authorize and @current_user.admin_level >= 1
	end
  
  def load_current_user
  	@current_user = User.find_by_id_and_deleted(session[:user_id], false)
  end
  
  def authorize
  	unless load_current_user
  		redirect_to :controller => :login, :action => :index
  		return false
  	end
  end
 
  def get_search_conditions search, fields
  	words = search.to_s.split ' '
  	return([]) if words.empty?
  	words.collect { |w|
  		fields.collect { |f, type|
				case type
					when :eq
						DB.escape("(#{f} = '%s')", w)
					when :like
						DB.escape("(#{f} like '%%%s%%')", w)
					when :left
						DB.escape("(#{f} like '%s%%')", w)
				end
  		}.join ' or '
  	}
  end
  
  def get_where c
  	c = c.reject &:blank?
  	return nil if c.empty?
  	'(' + c.join(') and (') + ')'
  end

end
