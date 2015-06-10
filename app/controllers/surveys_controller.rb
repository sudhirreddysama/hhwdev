class SurveysController < ApplicationController

	before_filter :require_perm_subadmin, :except => :take

	def index
		@surveys = Survey.find :all, :order => 'name', :conditions => 'deleted = 0'
	end
	
	def new
		@survey = Survey.new params[:survey]
		if request.post? and @survey.save
			flash[:notice] = 'Survey has been saved.'
			redirect_to :action => :index
		end
	end
	
	def edit
		@survey = Survey.find params[:id]
		if request.post? and @survey.update_attributes params[:survey]
			flash[:notice] = 'Survey has been saved.'
			redirect_to :action => :index
		end
	end
	
	def delete
		@survey = Survey.find params[:id]
		if request.post? and @survey.fake_destroy
			flash[:notice] = 'Survey has been deleted.'
			redirect_to :action => :index
		end
	end

	def view
		@survey = Survey.find params[:id], :include => {:questions => :answers}
		@totals, @results, @percentages, @comments = @survey.results
	end

	def take
		if params[:id] and (@appointment = Appointment.find_by_survey_key params[:id]) and (@survey = @appointment.survey)
			@answers = params[:answers] || {}
			if request.post?
				if @answers.size == @survey.questions.size
					@answers.each { |i, a|
						@appointment.answers.create :question_id => i, :answer => a
					}
					@appointment.update_attributes :survey_comment => params[:comments], :survey_taken => true
					redirect_to
				else
					@errors = ['Please answer all questions.']
				end
			end
		else
			render :text => ''
		end
	end
	
	def questions
		@survey = Survey.find params[:id]
	end
	
	def new_question
		@survey = Survey.find params[:id]
		if request.post?
			q = @survey.questions.create :text => params[:text], :order => @survey.questions.maximum('`order`')
			render(:update) { |p|
				p.insert_html :before, 'new', :partial => 'question', :locals => {:question => q}
				p['new_text'].value = ''
			}
		end
	end
	
	def update_question
		if request.post?
			q = Question.find params[:id]
			q.update_attribute :text, params[:text]
			render :text => q.text
		end
	end
	
	def delete_question
		if request.post?
			q = Question.find params[:id]
			q.destroy
			render(:update) { |p|
				p.remove "question_#{q.id}"
			}
		end
	end
	
	def order_questions
		if request.post?
			params[:question_list].each_with_index { |id, i|
				Question.find(id).update_attribute :order, i
			}
			render :nothing => true
		end
	end
	
end