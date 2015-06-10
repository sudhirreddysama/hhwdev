class Location < ActiveRecord::Base

	has_many :schedules
	has_many :blocks, :through => :schedules
	has_many :appointments, :through => :blocks
	
	validates_presence_of :name, :address, :city, :state, :zip
	
	def fake_destroy
		update_attribute :deleted, true
	end

end