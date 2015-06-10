class Answer < ActiveRecord::Base

	belongs_to :appointment
	belongs_to :question

end