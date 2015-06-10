class ExportController < ApplicationController

	before_filter :require_perm_subadmin

	def index
		if request.post?
			@errors = []
			if params[:locations].blank?
				@errors << 'No locations selected!'
			end
			since_date = Date.parse(params[:since]) unless params[:since].blank? rescue @errors << 'Invalid date!'
			if @errors.empty?
				ap = Appointment.find :all, :include => [{:block => :schedule}, :location], 
					:conditions => 'appointments.cancelled = 0 and (appointments.email = "" or appointments.email is null) and blocks.id is not null and schedules.id is not null ' +
					'and (schedules.date > (date(now()) + interval 2 day)) ' +
					'and appointments.created_at > ' +
					(since_date ? "'#{since_date}'" : 'locations.last_export') + ' and appointments.location_id in (' + params[:locations].collect { |id| id.to_i }.join(',') + ')'
				if ap.empty?
					@errors << 'Nothing to export!'
				else
					ex = ''
					CSV::Writer.generate(ex) { |csv|
						csv << [
							'created_at',
							'created_by',
							'appointment_date_time',
							'first_name',
							'last_name',
							'phone',
							'address1',
							'address2',
							'city',
							'municipality',
							'state',
							'zip',
							'collection_name',
							'collection_address1',
							'collection_address2',
							'collection_city',
							'collection_state',
							'collection_zip']
						
						ap.each { |a| 
							csv << [
								(a.created_at.strftime('%m/%d/%Y %I:%M %p') rescue nil), 
								(a.user.username rescue nil), 
								(a.when.strftime('%m/%d/%Y %I:%M %p') rescue nil),
								a.first_name,
								a.last_name,
								a.phone,
								a.address,
								a.address2,
								a.city,
								a.municipality,
								a.state,
								a.zip,
								(a.location.name rescue nil),
								(a.location.address rescue nil),
								(a.location.address2 rescue nil),
								(a.location.city rescue nil),
								(a.location.state rescue nil),
								(a.location.zip rescue nil)
							]
						}
					}
					send_data ex, :filename => 'export.csv'
					params[:locations].each { |id|
						Location.find(id).update_attribute :last_export, Time.now
					}
					return
				end
			end
		end
		@locations = Location.find :all, :order => 'name', :conditions => {:deleted => false}
	end

end