require 'rubygems'
require 'json'
require 'net/http'

# DES login to manage email list:
# https://www.constantcontact.com
# user: monroecounty
# pass: ctct123

# Developer login:
# https://constantcontact.mashery.com/login
# jessesternbergmc
# ad.IS.34.email

module ConstantContact

	def self.add_contact(email, first_name, last_name)
		app_key = 't6yyd9cxa3zcq2y963q427np'
		access_key = 'fc1b1c5d-3d2b-4486-ba13-b151d85f9513'
		uri = URI.parse "https://api.constantcontact.com/v2/contacts?api_key=#{app_key}"

		http = Net::HTTP.new(uri.host, uri.port)
		http.use_ssl = true

		header = {'Content-Type'=> 'application/json', 'Authorization' => "Bearer #{access_key}" }
		request = Net::HTTP::Post.new(uri.request_uri, header)
		user = {"status"=>"ACTIVE","lists"=>[{"id"=>"1386195626"}],"email_addresses"=> [{"status"=>"ACTIVE","email_address"=>email}], "first_name"=>first_name,"last_name"=>last_name}

		request.body = user.to_json
		response = http.request(request)
		data = JSON.parse(response.body)
		if data['results'].empty?
			p 'DOESNT EXIST'
		else
			p 'EXISTS'
		end
	end

end