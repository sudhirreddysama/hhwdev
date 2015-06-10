class AppointmentsController < ApplicationController
	
	before_filter :authorize, :except => :municipality_select
	
	def index
		@begin = params[:id] ? Date.parse(params[:id]) : Time.now.to_date.beginning_of_month 
		@end = @begin.advance :months => 4
		@objs = Schedule.find(:all, :include => [:blocks, :location], :order => 'locations.city, locations.name, schedules.date, blocks.time',
			:conditions => [((@current_user.admin_level >= 1) ? '' : 'schedules.date >= date(now()) and ') + 'schedules.date >= ? and schedules.date < ? and schedules.deleted = 0 and (blocks.disabled = 0 or blocks.id is null)', @begin, @end])
		
		@schedules = @objs.group_by &:date
			
	end
	
	def new
		@block = Block.find params[:id], :include => :schedule
		d = @block.schedule.date
		t = @block.time
		if @block.available? or @block.schedule.over? or @current_user.admin_level >= 1
			@appointment = @block.appointments.build({
				:user => @current_user, 
				:walk_in => @block.schedule.over?, 
				:export => !@block.schedule.over?, 
				:location_id => @block.schedule.location_id,
				:when => Time.utc(d.year, d.month, d.day, t.hour, t.min, 0)
			})
			@appointment.current_user = @current_user
			@appointment.attributes = params[:appointment]
			@appointment.no_show = false if @appointment.walk_in
			if request.post? and @appointment.save
				@block.update_attribute :appointments_count, @block.appointments_count + 1
				unless @appointment.email.blank?
					Notifier.deliver_confirmation @appointment
				end
				unless @appointment.comments.blank? and @appointment.admin_comments.blank?
					Notifier.deliver_comments @appointment
				end
				flash[:notice] = 'Appointment has been saved.'
				redirect_to :action => :view, :id => @appointment.id
			end
		else
			flash[:error] = 'Sorry, but the time you have chosen is no longer available. There may haved been another user who was reserving this space at the same time. Please choose another date or time.'
			redirect_to :action => :index
		end
	end
	
	def edit
		@appointment = Appointment.find params[:id]
		@appointment.current_user = @current_user
		if request.post?
			@appointment.attributes = params[:appointment]
			@appointment.no_show = false if @appointment.walk_in
			if @appointment.save
				flash[:notice] = 'Appointment has been saved.'
				redirect_to :action => :view, :id => @appointment.id
			end
		end
	end
	
	def delete
		@appointment = Appointment.find params[:id]
		@appointment.current_user = @current_user
		if request.post?
			@appointment.update_attributes :cancelled => true, :no_show => false, :walk_in => false
			@appointment.block.update_attribute :appointments_count, @appointment.block.appointments_count - 1
			flash[:notice] = 'Appointment has been cancelled.'
			redirect_to :action => :index
		end
	end
	
	def view
		@appointment = Appointment.find params[:id]
	end
	
	def search_for_previous
		@appointment = Appointment.find_previous params[:phone]
		render(:update) { |p|
			if @appointment
				p['appointment_first_name'].value = @appointment.first_name.to_s
				p['appointment_last_name'].value = @appointment.last_name.to_s
				p['appointment_email'].value = @appointment.email.to_s
				p['appointment_address'].value = @appointment.address.to_s
				p['appointment_address2'].value = @appointment.address2.to_s
				p['appointment_zip'].value = @appointment['zip'].to_s
				p['previous_count'].update "Previous Appointments: #{@appointment.previous_count}" + ((@appointment.flagged.to_i == 1) ? ' <span style="color: #a00; font-weight: bold;">FLAGGED! ' + @appointment.sig_comment + '</span>' : '')
				p.replace 'appointment_municipality', :partial => 'municipality_select', :locals => {:zip => @appointment['zip'].to_s, :municipality => @appointment.municipality}
			else
				p.alert 'No previous record found.'
			end
		}
	end
	
	def municipality_select
		render(:update) { |p|
			p.replace 'appointment_municipality', :partial => 'municipality_select', :locals => {:zip => params[:zip], :municipality => params[:municipality]}
		}
	end
	
	def transfer
		@appointment = Appointment.find params[:id]
		@appointment.current_user = @current_user
		if request.post?
			@block = Block.find params[:new_block_id]
			if @block.available? or @block.schedule.over? or @current_user.admin_level > 1
				if @block.id != @appointment.block_id
					@block.update_attribute :appointments_count, @block.appointments_count + 1
					@appointment.block.update_attribute :appointments_count, @appointment.block.appointments_count - 1
					@appointment.block = @block
					@appointment.location_id = @block.schedule.location_id
					d = @block.schedule.date
					t = @block.time
					@appointment.when = Time.utc(d.year, d.month, d.day, t.hour, t.min, 0)
					unless @appointment.email.blank?
						Notifier.deliver_confirmation @appointment
					end
					@appointment.created_at = Time.now
					@appointment.user = @current_user
					@appointment.save
				end
				redirect_to :action => :view, :id => @appointment.id, :id2 => nil
				flash[:notice] = 'Appointment has been transfered.'
				return
			end
			flash[:error] = 'Sorry, but the time you have chosen is no longer available. There may haved been another user who was reserving this space at the same time. Please choose another date or time.'
		end
		params[:id] = params[:id2]
		index
		render :action => :index
	end

end