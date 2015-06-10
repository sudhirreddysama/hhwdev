class SchedulesController < ApplicationController
	
	before_filter :authorize, :only => [:index, :view, :sig_sheet, :toggle_no_show]
	before_filter :require_perm_admin, :only => [:new, :edit, :delete, :send_survey, :merge]
	
	def index
		if request.post?
			@filter = params[:filter]
			@filter.errors = []
			@filter.begin_date = Date.parse(@filter.begin) rescue @filter.errors << 'Invalid value for begin date.' unless @filter.begin.blank?
			@filter.end_date = Date.parse(@filter.end) rescue @filter.errors << 'Invalid value for end date.' unless @filter.end.blank?
		else
			b = Time.now.to_date
			if @current_user.admin_level > 0
				b = b.advance(:weeks => -2)
			end
			@filter = {:begin => b.strftime('%B %d, %Y'), :begin_date => b}
		end
		
		c = ['schedules.deleted = 0']
		c << "schedules.date >= '#{@filter.begin_date.to_date}'" if @filter.begin_date
		c << "schedules.date <= '#{@filter.end_date.to_date}'" if @filter.end_date
		c << "blocks.disabled = 0" if @current_user.admin_level < 2
		@schedules = Schedule.find :all, :order => 'schedules.date, schedules.begin', :include => [:location, :blocks],
			:conditions => get_where(c)
	end
	
	def new
		@schedule = Schedule.new params[:schedule]
		if request.post? and @schedule.save
			flash[:notice] = 'Schedule has been saved.'
			redirect_to :action => :view, :id => @schedule.id
		end
	end
	
	def edit
		@schedule = Schedule.find params[:id]
		if request.post? and @schedule.update_attributes params[:schedule]
			@schedule.update_blocks
			flash[:notice] = 'Schedule has been saved.'
			redirect_to :action => :view, :id => @schedule.id
		end
	end
	
	def delete
		@schedule = Schedule.find params[:id]
		if request.post? and @schedule.fake_destroy
			flash[:notice] = 'Schedule has been deleted.'
			redirect_to :action => :index
		end
	end

	def view
		@schedule = Schedule.find params[:id], :include => [:location, {:blocks => :appointments}], :order => 'blocks.time, appointments.last_name, appointments.first_name',
			:conditions => ('blocks.disabled = 0' if @current_user.admin_level < 2)
	end
	
	def signatures
		@schedule = Schedule.find params[:id], :include => [:location, {:blocks => :appointments}], :order => 'blocks.time, appointments.last_name, appointments.first_name',
			:conditions => 'appointments.cancelled = 0 and appointments.id is not null'
		htmldoc = IO.popen('HTMLDOC_NOCGI=TRUE;export HTMLDOC_NOCGI;htmldoc -t pdf --path "' + Dir.pwd + '/public/images" --size letter --webpage --quiet --bodyfont Arial --fontsize 10 --headfootsize 10 --bottom .5in --top .5in --left .5in --right .5in serif -', 'w+')
		htmldoc.puts render_to_string(:layout => false)
		htmldoc.close_write
		send_data htmldoc.read, :filename => 'sigsheet.pdf'
		htmldoc.close
	end

	
	def toggle_no_show
		if request.post?
			Appointment.find(params[:id]).update_attributes :no_show => params[:value], :cancelled => false, :walk_in => false
		end
		render :nothing => true
	end
	
	def send_survey
		if request.post?
			err = []
			err << 'No recipients specified.' if params[:recipients].blank?
			err << 'No survey specified.' if params[:survey_id].blank?
			if err.empty?
				params[:recipients].each { |id|
					a = Appointment.find id
					a.update_attributes :survey_id => params[:survey_id], :survey_key => Survey.generate_key
					Notifier.deliver_survey a
				}
				flash[:notice] = 'Survey has been sent.'
			else
				flash[:error] = err.join('<br/>')
			end
		end
		redirect_to :action => :view, :id => params[:id]
	end
	
	def toggle_block
		if request.post?
			@block = Block.find_by_id params[:id]
			@block.update_attribute :disabled, params[:value].blank?
			render :nothing => true
		end
	end
	
	def merge
		@obj = Schedule.find params[:id]
		@schedule = @obj
		@objs = Schedule.find :all, :conditions => ['deleted = 0 and date = ? and location_id = ? and schedule_type_id = ? and id != ?', @obj.date, @obj.location_id, @obj.schedule_type_id, @obj.id]
		if request.post?
			@objs.each { |o|
				logger.info "Merging #{o.name} into #{@obj.name}"
				o.blocks.each { |b|
					b.update_attribute :schedule_id, @obj.id
					logger.info "Merging Block #{b.id}"
				}
				@obj.end = o.end if o.end > @obj.end
				@obj.begin = o.begin if o.begin < @obj.begin
				o.fake_destroy
			}
			@obj.save
			flash[:notice] = 'Schedules have been merged.'
			redirect_to :action => :view, :id => @obj.id
		end
	end
	
end