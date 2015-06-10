class LoginController < ApplicationController

	before_filter :authorize, :except => :index

	def index
		if request.post?
			if u = User.authenticate(params[:username], params[:password])
				session[:user_id] = u.id
				flash[:notice] = 'You have successfully logged in.'
				redirect_to root_url
			else
				@errors = ['Login failed.']
			end
		end
	end

	def logout
		reset_session
		flash[:notice] = 'You have successfully logged out.'
		redirect_to :action => :index
	end
	
	def edit
		@user = @current_user
		if request.post? and @user.update_attributes params[:user]
			flash[:notice] = 'Your account has been updated.'
			redirect_to root_url
		end
	end
	
end