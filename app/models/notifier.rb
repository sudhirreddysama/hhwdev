class Notifier < ActionMailer::Base
	
	FROM = 'Monroe County HHW <Household_hazardous_waste@monroecounty.gov>'
	
	helper :application
	
	def confirmation a
		from FROM
		recipients a.email_with_name
		subject 'HHW Appointment Confirmation : ' + a.location.name
		body :a => a
	end
	
	def comments a
		from FROM
		recipients FROM
		subject 'HHW Appointment Comment Notification : ' + a.location.name
		body :a => a
	end
	
	def survey a
		from FROM
		recipients a.email_with_name
		subject 'Monroe County HHW Satisfaction Survey : ' + a.location.name
		body :a => a
	end

	def recipients *args
		if RAILS_ENV == 'development'
			super 'jessesternberg@monroecounty.gov'
		else
			super *args
		end
	end

end
