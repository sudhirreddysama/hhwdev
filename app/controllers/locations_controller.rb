class LocationsController < ApplicationController

	before_filter :require_perm_admin

	def index
		@locations = Location.find :all, :order => 'name', :conditions => 'deleted = 0'
	end
	
	def new
		@location = Location.new params[:location]
		if request.post? and @location.save
			flash[:notice] = 'Location has been saved.'
			redirect_to :action => :index
		end
	end
	
	def edit
		@location = Location.find params[:id]
		if request.post? and @location.update_attributes params[:location]
			flash[:notice] = 'Location has been saved.'
			redirect_to :action => :index
		end
	end
	
	def delete
		@location = Location.find params[:id]
		if request.post? and @location.fake_destroy
			flash[:notice] = 'Location has been deleted.'
			redirect_to :action => :index
		end
	end

end