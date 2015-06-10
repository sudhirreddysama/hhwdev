class Schedule < ActiveRecord::Base

	belongs_to :location
	has_many :blocks, :dependent => :destroy, :order => 'blocks.time'
	has_many :appointments, :through => :blocks
	belongs_to :schedule_type
	
	validates_presence_of :location_id, :date, :begin, :end, :interval, :slots, :schedule_type
	
	def available?
		blocks.detect &:available?
	end
	
	def name
		"#{location.name} #{date.strftime '%m/%d/%Y'} #{self.begin.strftime '%I:%M %p'}"
	end

	def fake_destroy	
		if blocks.sum(:appointments_count).to_i > 0
			errors.add_to_base 'This schedule has appointments and cannot be deleted. You must first cancel these appointments.'
			return false		
		end
		update_attribute :deleted, true
	end
	
	def over?
		date <= Time.now.to_date
	end
	
	def check_seconds
		self.begin = self.begin.change(:sec => 0) 
		self.end = self.end.change(:sec => 0)
	end
	before_save :check_seconds
	
	def create_blocks
		if interval.to_i > 0
			t = self.begin.clone
			while t < self.end
				blocks.create :time => t, :slots => slots
				t = t.advance :minutes => interval
			end
		end
	end
	after_create :create_blocks
	
	def update_blocks
		if interval.to_i > 0
			#blocks.update_all :slots => slots
			
			slots_multiple.each { |o, s|
				DB.query 'update blocks set slots = %d where schedule_id = %d and slots = %d', s, id, o
				#blocks.update_all {:slots => s}, {:conditions => ['blocks.slots = ?', o]}
			}
			
			block_times = blocks.index_by &:time
			t = self.begin.clone
			while t < self.end
				blocks.create :time => t, :slots => slots unless block_times[t]
				t = t.advance :minutes => interval
			end
		end
	end
	#after_update :update_blocks
	
	def slots_multiple
		return @slots_multiple if @slots_multiple
		@slots_multiple = {}
		blocks.each { |b|
			@slots_multiple[b.slots] = b.slots
		}
		return @slots_multiple
	end
	
	def slots_multiple= v
		@slots_multiple = v
	end
	
end