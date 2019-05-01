# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

	#
	# Renders tabs. Tabs will be current if p1 matches whats in params. p2 will also be sent to link_to
	# but don't effect whether or not the tab is open.
	#
	def tab txt, p1, p2 = {}, opt = {}
		opt[:class] = 'current' if p1.all? { |k, v| !v or params[k].to_s == v.to_s }
		link_to txt, p1.merge(p2), opt
	end
	
	def directions_link a
		l = a.location
		return 'http://maps.google.com/maps?f=d&ttype=&saddr=' + CGI.escape("#{a.address} #{a.city} #{a.state} #{a.zip}") + '&daddr=' + CGI.escape("#{l.address} #{l.city} #{l.state} #{l.zip}")
		#'http://maps.yahoo.com/?q1=' + CGI.escape("#{a.address} #{a.city} #{a.state} #{a.zip}") + '&q2=' + CGI.escape("#{l.address} #{l.city} #{l.state} #{l.zip}")
	end

	def nl2br s
	  s.to_s.gsub(/\n/, '<br />')
 	end
 	
	def nl2br_h s
 		nl2br h(s)
 	end
 	
	def partial p, l = nil
		render :partial => p, :locals => l
	end

	def short_date(d)
		"#{d.month}/#{d.day}/#{d.year.to_s[-2,2]}"
	end
	
	def short_time(t)
		"#{t.strftime('%I').to_i}:#{t.strftime('%M')}#{t.strftime('%p').downcase}"
	end

end
