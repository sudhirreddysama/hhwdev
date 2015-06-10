class ContentController < ApplicationController

	before_filter :require_perm_admin

	def index
		if request.post?
			Content.find(params[:id]).update_attributes params[:content]
			flash[:notice] = 'Content has been updated.'
			redirect_to
		else
			@contents = Content.find :all
		end
	end

end