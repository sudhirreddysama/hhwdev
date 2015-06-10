class User < ActiveRecord::Base

	validates_presence_of :username
	validates_format_of :username, :with => /\A[a-zA-Z0-9_]*\Z/
	validates_uniqueness_of :username
	validates_confirmation_of :password, :if => :password
	validates_presence_of :password, :on => :create
	validates_length_of :password, :minimum => 4, :if => :password
	
  def password= v
  	unless v.to_s.empty?
			self.encrypted_password = Digest::MD5.hexdigest(v)
			@password = v
  	end
  end
  attr_reader :password
  
  def self.authenticate u, p
  	find_by_username_and_encrypted_password_and_deleted u, Digest::MD5.hexdigest(p), false
  end
  
	USER_TYPES = ['Customer Service', 'Subadmin', 'Admin']

	def type
		USER_TYPES[admin_level]
	end
	
	def fake_destroy
		update_attribute :deleted, true
	end
	
end