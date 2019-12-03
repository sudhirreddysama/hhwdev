require 'constant_contact.rb'

class Appointment < ActiveRecord::Base

	has_many :answers
	belongs_to :block
	belongs_to :survey
	belongs_to :user
	belongs_to :location
	
	validates_format_of :area_code, :with => /\A\d{3}\Z/
	validates_format_of :phone_number, :with => /\A\d{7}\Z/
	validates_presence_of :first_name, :last_name, :address
	validates_format_of :zip, :with => /\A\d{5}/
	validates_presence_of :municipality, :if => Proc.new { |a| !a.current_user or a.current_user.admin_level <= 1 }
	validates_presence_of :email, :if => 'online'
	validates_confirmation_of :email, :if => 'online'
	
	attr :current_user, true 
	
	def area_code
		@area_code || phone.to_s[0..2]
	end
	
	def phone_number
		@phone_number || phone.to_s[3..9]
	end
	
	def extension
		@extension || phone.to_s[10..-1]
	end
	
	attr_writer :area_code, :phone_number, :extension
	
	def compose_phone; 
		self.phone = "#{area_code}#{phone_number}#{extension}"
	end
	before_save :compose_phone
	
	def set_city
		self.city = City.find_by_zip(zip.to_s[0..4]).name
	end
	before_save :set_city
	
	def self.get_report_conditions location_id = nil, begin_date = nil, end_date = nil, field = 'when', long_table_name = false
		tbl = long_table_name ? 'appointments' : 'a'
		if location_id or begin_date or end_date
			c = []
			c << "(date(#{tbl}.#{field}) >= '#{begin_date}')" if begin_date
			c << "(date(#{tbl}.#{field}) <= '#{end_date}')" if end_date
			c << "(#{tbl}.location_id = #{location_id})" if location_id
			c.join(' and ')
		end
	end
	
	def self.report group_by = nil, location_id = nil, begin_date = nil, end_date = nil, field = 'when'
		c = get_report_conditions location_id, begin_date, end_date, field
		connection.execute <<EOS
			select
			
			coalesce(count(a.id), 0) appointment_total,
			coalesce(sum(a.no_show), 0) no_show_total,
			coalesce(sum(a.walk_in), 0) walk_in_total,
			coalesce(sum(a.online), 0) online_total,
			coalesce(sum(a.cancelled), 0) cancelled_total,
			coalesce(sum(if(a.email = "" or email is null, 0, 1)), 0) email_total,

			hour(a.#{field}) hour,
			weekday(a.#{field}) weekday,
			dayname(a.#{field}) dayname,
			substring(a.zip, 1, 5) zip,
			yearweek(a.#{field}) yearweek, 
			a.municipality municipality
			
			from appointments a 
			#{"where #{c}" if c}
			group by #{group_by || '"ALL"'}
EOS
	end
	
	def self.repeat_report location_id = nil, begin_date = nil, end_date = nil, field = 'when'		
		c = get_report_conditions location_id, begin_date, end_date, field
		result = connection.execute <<EOS
			select count(*) times, a3.*
			from appointments a
			join (select a2.*, max(a2.created_at) from appointments a2 group by a2.phone) a3
			where a3.phone = a.phone
			#{"and #{c}" if c}
			group by a.phone having times > 1 order by times desc, a.last_name, a.first_name
EOS
		rep = OrderedHash.new
		while r = result.fetch_hash
			rep[r.times] ||= []
			rep[r.times] << r
		end
		rep
	end

	def fake_destroy
		update_attribute :deleted, true
	end
	
  def email_with_name
    "#{first_name} #{last_name} <#{email}>"
  end
  
  def name
  	"#{first_name} #{last_name}, #{self.when.strftime '%m/%d/%Y %I:%M %p' rescue 'unknown date / time' }"
  end
  
  def self.find_previous phone
  	phone = connection.quote_string phone
  	p = connection.execute("select a.* from appointments a where a.created_at = (select max(a2.created_at) from appointments a2 where left(a2.phone, 10) = '#{phone}') and left(a.phone, 10) = '#{phone}'").fetch_hash
  	if p
  		p['previous_count'] = connection.execute("select count(*) previous_count from appointments a2 where left(a2.phone, 10) = '#{phone}'").fetch_hash['previous_count']
  	end
  	p
  end
  
  def previous_count
  	Appointment.count(:conditions => {:phone => phone}) - 1
  end
	
	def set_flagged
		Appointment.update_all "flagged = #{flagged ? 1 : 0}", ['phone = ?', phone]
		return true
	end
	before_update :set_flagged
	
	def check_flagged
		other = Appointment.find :first, :conditions => ['phone = ?', phone]
		self.flagged = other.flagged if other
		return true
	end
	before_create :check_flagged 
	
	def generate_email_key
		if email_key.blank?
			sample = 'bcdfghjklmnpqrstvwxyz0123456789'
			self.email_key = 10.times.map { sample[rand(sample.size)].chr }.join
		end
	end
	before_save :generate_email_key

	def email_setup_in_constantcontact
		ConstantContact.add_contact(email, first_name, last_name)
	end
end