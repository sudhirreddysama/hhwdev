class MobileController < ApplicationController
	
	before_filter :mobile_authorize, :except => :login

	def login
		if load_current_user
			redirect_to :action => :schedule
			return
		end
		if request.post?
			if u = User.authenticate(params[:username], params[:password])
				session[:user_id] = u.id
				redirect_to :action => :schedule
			else
				@errors = ['Login failed.']
			end
		end
	end
	
	def logout
		reset_session
		redirect_to :action => :login
	end

	def index
		redirect_to :action => :schedule
	end
	
	def schedule
		@schedules = Schedule.find(:all, {
			:order => 'schedules.date, schedules.begin', 
			:include => :location, 
			:conditions => 'schedules.deleted = 0 and schedules.date between date_add(date(now()), interval -2 day) and date_add(date(now()), interval 1 year)'
		})
		if !params[:id]
			@schedules.each { |s|
				if s.date >= Date.today
					redirect_to :id => s.id
					return
				end
			}
		end
		@schedule = Schedule.find params[:id]
		@blocks = @schedule.blocks :conditions => 'blocks.enabled = 1'
	end
	
	def toggle
		appt = Appointment.find params[:id2]
		field = params[:id]
		if !%w{no_show flagged signed_in}.include?(field)
			render :nothing => true
			return
		end
		field = field.to_sym
		v = params[:value] == '1'
		attr = {field => v}
		if v
			attr[:signed_in] = false if field == :no_show
			attr[:no_show] = false if field == :signed_in
		end
		appt.update_attributes attr
		render :text => appt.send(field) ? '1' : '0'
	end
	
	def license_plate
		appt = Appointment.find params[:id]
		appt.update_attribute :license_plate, params[:value]
		render :nothing => true
	end
	
	def edit
		@obj = Appointment.find params[:id]
		@obj.current_user = @current_user
		if request.post?
			@obj.attributes = params[:obj]
			@obj.no_show = false if @obj.walk_in
			if @obj.save
				@schedule = @obj.block.schedule
				html = render_to_string :partial => 'appointment', :locals => {:a => @obj}, :layout => false
				render :json => {:el => "#appt-#{@obj.id}", :op => 'replaceWith', :html => html}.to_json
				return
			end
		end
		render :layout => false
	end
	
	def new
		@block = Block.find params[:id], :include => :schedule
		d = @block.schedule.date
		t = @block.time
		@obj = @block.appointments.build({
			:email_signup => true
		})		
		@obj.attributes = params[:obj] if request.post?
		@obj.attributes = {
			:user => @current_user, 
			:walk_in => true, 
			:export => !@block.schedule.over?, 
			:location_id => @block.schedule.location_id,
			:when => Time.utc(d.year, d.month, d.day, t.hour, t.min, 0),
			:no_show => false
		}
		if request.post? and @obj.save
			@block.update_attribute :appointments_count, @block.appointments_count + 1
			unless @obj.email.blank?
				Notifier.deliver_confirmation @obj
			end
			unless @obj.comments.blank? and @obj.admin_comments.blank?
				Notifier.deliver_comments @obj
			end
			@schedule = @obj.block.schedule
			html = render_to_string :partial => 'appointment', :locals => {:a => @obj}, :layout => false
			render :json => {:el => "#appts-#{@obj.block.id}", :op => 'append', :html => html}.to_json
			return
		end
		render :layout => false
	end
	
	def search_prev
		@obj = Appointment.find_previous params[:phone]
		if @obj
			data = {
				:first_name => @obj.first_name,
				:last_name => @obj.last_name,
				:email => @obj.email,
				:address => @obj.address,
				:address2 => @obj.address2,
				:zip => @obj['zip'],
				:previous_count => @obj.previous_count.to_i,
				:municipality => @obj.municipality,
				:flagged => @obj.flagged.to_i == 1,
				:sig_comment => @obj.sig_comment
			}
		else 
			data = 'NOT FOUND'
		end
		render :json => data.to_json
	end
	
	private
	
	def mobile_authorize
  	unless load_current_user
  		redirect_to :action => :login
  		return false
  	end
  end

end