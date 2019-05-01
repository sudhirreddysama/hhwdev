class ReportsController < ApplicationController

	before_filter :parse_filter
	before_filter :require_perm_admin
	
	def index
		@total = Appointment.report nil, @filter.location_id, @filter.begin_date, @filter.end_date, @filter.date
		@weekday = Appointment.report '`weekday`', @filter.location_id, @filter.begin_date, @filter.end_date, @filter.date
		@hour = Appointment.report '`hour`', @filter.location_id, @filter.begin_date, @filter.end_date, @filter.date
		@zip = Appointment.report '`zip`', @filter.location_id, @filter.begin_date, @filter.end_date, @filter.date
		@municipality = Appointment.report '`municipality`', @filter.location_id, @filter.begin_date, @filter.end_date, @filter.date
		@yearweek = Appointment.report '`yearweek`', @filter.location_id, @filter.begin_date, @filter.end_date, @filter.date
	end
	
	def repeat
		@repeat = Appointment.repeat_report @filter.location_id, @filter.begin_date, @filter.end_date, @filter.date
	end
	
	def parse_filter
		if request.post?
			@filter = params[:filter]
			@filter.errors = []
			@filter.location_id = @filter.location_id.blank? ? nil : @filter.location_id.to_i
			@filter.begin_date = Date.parse(@filter.begin) rescue @filter.errors << 'Invalid value for begin date.' unless @filter.begin.blank?
			@filter.end_date = Date.parse(@filter.end) rescue @filter.errors << 'Invalid value for end date.' unless @filter.end.blank?
			if params[:commit] == 'Export' and @filter.errors.empty?
				export
			end
		else
			b = Time.now.to_date.advance(:years => -1)
			@filter = {:begin => b.strftime('%B %d, %Y'), :begin_date => b, :date => 'when'}
		end
	end
	
	def export
		ex = ''
		c = Appointment.get_report_conditions @filter.location_id, @filter.begin_date, @filter.end_date, @filter.date, true
		ap = Appointment.find :all, :conditions => c, :include => :location
		CSV::Writer.generate(ex) { |csv|
			csv << [
				'created_at',
				'created_by',
				'appointment_date_time',
				'cancelled',
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
					a.cancelled,
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
	end
	
	def perweek
		result = DB.query 'select
			count(*) total, week(a.created_at) week_of_year, year(a.created_at) year, a.created_at sample_created_at
			from appointments a
			group by concat(year(a.created_at), week(a.created_at))
			order by a.created_at '
		str = ''
		CSV::Writer.generate(str) { |csv|
			csv << [
				'total',
				'week_of_year',
				'year',
				'sample']
			result.each_hash { |h|
				csv << [
					h['total'],
					h['week_of_year'],
					h['year'],
					h['sample_created_at']]
			}
		}
		send_data str, :filename => 'report.csv'
	end
	
end