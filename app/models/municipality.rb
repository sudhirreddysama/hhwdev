class Municipality < ActiveRecord::Base

	def self.munis_by_zip
		munis = Hash.new { |h, k| h[k] = [] }
		find(:all).each { |m| munis[m.zip] << m.name }
		munis
	end

end