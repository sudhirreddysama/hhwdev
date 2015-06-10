class SearchController < ApplicationController
	
	before_filter :authorize
	
	def index
		params[:page] ||= 1
		@filter = session[:appointment_filter] || {}
		if request.post?
			@filter = params[:filter]
			@filter.begin_date = Date.parse(@filter.begin) rescue @filter.errors << 'Invalid value for begin date.' unless @filter.begin.blank?
			@filter.end_date = Date.parse(@filter.end) rescue @filter.errors << 'Invalid value for end date.' unless @filter.end.blank?
			session[:appointment_filter] = @filter
		end
		
		c = get_search_conditions @filter[:search], {
				'appointments.first_name' => :like,
				'appointments.last_name' => :like,
				'appointments.phone' => :like,
				'appointments.email' => :like
			}
		c << "appointments.when >= '#{@filter.begin_date.to_date}'" if @filter.begin_date
		c << "appointments.when <= '#{@filter.end_date.to_date}'" if @filter.end_date
		
		@appointments = Appointment.paginate :all, :include => :location, 
			:order => 'appointments.when desc, appointments.first_name, appointments.last_name',
			:conditions => get_where(c),
			:page => params[:page]
	end

end