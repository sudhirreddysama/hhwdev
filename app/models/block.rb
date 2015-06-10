class Block < ActiveRecord::Base

	belongs_to :schedule
	has_many :appointments
	
	def available?
		appointments_count < slots
	end
	
	def availability
		slots - appointments_count
	end
	
end