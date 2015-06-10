class ReservationController < ApplicationController
	
	before_filter :users_get_outa_here
	def users_get_outa_here
		if load_current_user
			redirect_to :controller => :appointments, :action => :index, :id => nil
		end
	end
	
	def questions
		@agreement = params[:agreement] || {}
		if request.post? 
			@agreement.errors = ['You must answer &quot;yes&quot; or &quot;agree&quot; to every question before proceeding.'] if @agreement.size < 3 or @agreement.find { |k, a| a != 'Yes' }
			redirect_to :action => :agreement, :id => params[:id] if @agreement.errors.nil?
		end
	end
	
	def index
		@begin = params[:id] ? Date.parse(params[:id]) : Time.now.to_date.beginning_of_month 
		@end = @begin.advance :months => 4
		if @begin < Time.now.to_date
			@begin = Time.now.to_date
		end
		@objs = Schedule.find(:all, :include => [:blocks, :location], :order => 'locations.city, locations.name, schedules.date, blocks.time',
			:conditions => ['concat(schedules.date, "T", schedules.end) > now() and schedules.date >= ? and schedules.date < ? and schedules.deleted = 0 and ((blocks.slots > blocks.appointments_count and blocks.disabled = 0) or schedules.interval = 0)', @begin, @end])
			
		@schedules = @objs.group_by &:date
			
		render :template => 'appointments/index'
	end
	
	def agreement
		@agreement = params[:agreement] || {}
		@block = Block.find params[:id], :include => {:schedule => :location}
		if request.post?
			if @block.schedule.location.use_terms
				@agreement.errors = ['You must read and agree to the terms &amp; conditions before proceeding.'] unless @agreement[:agree] == 'yes'
			else
				@agreement.errors = ['Before proceeding you must answer &quot;yes&quot; to all questions and click the &quot;I have read...&quot; checkboxes for both the acceptable and unacceptable material lists.'] if @agreement.size < 5 or @agreement.find { |k, a| a != 'Yes' }
			end
			redirect_to :action => :personal, :id => params[:id] if @agreement.errors.nil?
		end
	end 
	
	def personal
		@block = Block.find params[:id], :include => :schedule
		d = @block.schedule.date
		t = @block.time
		if @block.available?
			@appointment = @block.appointments.build({
				:online => true,
				:location_id => @block.schedule.location_id,
				:when => Time.utc(d.year, d.month, d.day, t.hour, t.min, 0)
			})
			@appointment.attributes = params[:appointment]
			if request.post? and @appointment.save
				@block.update_attribute :appointments_count, @block.appointments_count + 1
				Notifier.deliver_confirmation @appointment
				unless @appointment.comments.blank? and @appointment.admin_comments.blank?
					Notifier.deliver_comments @appointment
				end
				flash[:notice] = 'Your appointment has been created.'
				session[:appointment_id] = @appointment.id
				redirect_to :action => :confirmed
			end
		else
			flash[:error] = 'Sorry, but the time you have chosen is no longer available. There may haved been another user who was reserving this space at the same time. Please choose another date or time.'
			redirect_to :action => :index
		end 
	end
	
	def confirmed
		@appointment = Appointment.find session[:appointment_id]
		render :template => 'appointments/view'
	end
	
	def not_found
		flash[:notice] = 'You accessed this site via an outdated or invalid link. You have been redirected to the home page.'
		redirect_to root_url
	end
	
end