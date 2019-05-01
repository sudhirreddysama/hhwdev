require 'rubygems'
require 'json'
require 'net/http'

module ConstantContact
		
	def self.add_contact email
		app_key = 't6yyd9cxa3zcq2y963q427np'
		access_key = 'fc1b1c5d-3d2b-4486-ba13-b151d85f9513'
		uri = URI.parse "https://api.constantcontact.com/v2/contacts?status=ALL&limit=1&api_key=#{app_key}&email=" + URI.encode(email)
		http = Net::HTTP.new(uri.host, uri.port)
		http.use_ssl = true
		request = Net::HTTP::Get.new(uri.request_uri)
		request['Authorization'] = "Bearer #{access_key}"
		response = http.request(request)
		data = JSON.parse(response.body)
		if data['results'].empty?
			p 'DOESNT EXIST'
		else
			p 'EXISTS'
		end
	end

end