class Survey < ActiveRecord::Base

	has_many :questions, :order => 'questions.`order`'
	has_many :appointments
	
	ANSWERS =  ['Strongly Disagree', 'Disagree', 'Indifferent', 'Agree', 'Strongly Agree']
	
	def fake_destroy
		update_attribute :deleted, true
	end
	
	def results
		totals = connection.execute("select sum(a.survey_taken) taken, count(*) sent from appointments a where a.survey_id = #{id}").fetch_hash
		result = connection.execute <<EOS
			select q.id id, a.answer answer, count(*) total
			from answers a
			join questions q on q.id = a.question_id
			join surveys s on s.id = q.survey_id
			where s.id = #{id} group by q.id, a.answer
EOS
		q_tot = {}
		while r = result.fetch_hash
			q_tot[r.id.to_i] ||= {}
			q_tot[r.id.to_i][r.answer.to_i] = r.total.to_i
		end
		q_perc = {}
		q_tot.each { |i, a|
			q_perc[i] = {}
			tot = a.inject(0) { |mem, t| mem += t[1] }
			a.each { |ans, ans_tot| q_perc[i][ans] = (ans_tot.to_f / tot * 100).round }
		}
		com = appointments.find :all, :conditions => 'appointments.survey_comment is not null and appointments.survey_comment != ""'
		[totals, q_tot, q_perc, com]
	end
	
	def self.generate_key
		begin
			key = ''
			20.times { key << rand(9).to_s }
		end while Appointment.find_by_survey_key key
		key
	end
	
end