class UsersController < ApplicationController
	
	before_filter :require_perm_admin
	
	def index
		@users = User.find :all, :order => 'username', :conditions => {:deleted => false}
	end
	
	def edit
		@user = User.find params[:id]
		if request.post? and @user.update_attributes params[:user]
			flash[:notice] = 'User has been updated.'
			redirect_to :action => :index, :id => nil
		end
	end

	def new
		@user = User.new params[:user]
		if request.post? and @user.save
			flash[:notice] = 'User has been created.'
			redirect_to :action => :index, :id => nil
		end
	end

	def delete
		@user = User.find params[:id]
		if request.post? and @user.fake_destroy
			flash[:notice] = 'User has been deleted.'
			redirect_to :action => :index, :id => nil
		end
	end
	
	def view
		@user = User.find params[:id]
	end

end