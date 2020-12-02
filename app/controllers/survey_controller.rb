require 'barby/barcode/data_matrix'
require 'barby/outputter/html_outputter'

class SurveyController < ApplicationController
  include Pagy::Backend

  before_action :authenticate_user!, except: [:show, :submit, :completed, :validation_check]
  before_action :notification_check, except: [:show, :submit, :completed, :validation_check]

  after_action :allow_iframe, only: [:show, :submit]
  protect_from_forgery with: :null_session


  def view
    @organization = current_user.organization
    @survey = @organization.surveys.find_by_id(params[:id])
    @total_responses = @survey.survey_responses.count
    @pagy, @responses = pagy(@survey.survey_responses.order('id DESC'), page_param: :responses)
    @today_responses_count = @survey.survey_responses.where("created_at BETWEEN ? AND ?", DateTime.now.beginning_of_day, DateTime.now.end_of_day).count
    if @survey.ordered_questions
      @questions = @survey.survey_questions.order(:order)
    else
      @questions = @survey.survey_questions.order(:id)
    end
    @pagy_a, @answers = pagy(@survey.survey_responses.order('id DESC'), page_param: :answers)

    # Response Chart
    @data_array = Array.new
    iterating_date = @survey.start_date_time
    while iterating_date < @survey.end_date_time
      @data_array.push([iterating_date.in_time_zone(@organization.timezone).to_i * 1000, @survey.survey_responses.where("created_at BETWEEN ? AND ?", iterating_date.beginning_of_day, iterating_date.end_of_day).count])
      iterating_date = iterating_date + 1.days
    end
  end

  def overview
    @time = DateTime.now
    @pagy, @surveys = pagy(current_user.organization.surveys.order("created_at DESC"), limit: 12)
  end

  def new
    @current_organization = current_user.organization
    @survey = Survey.new
    if params[:name]
      @survey.name = params[:name]
    end
    if params[:description]
      @survey.description = params[:description]
    end
    if params[:start_message]
      @survey.start_message = params[:start_message]
    end
    if params[:completion_message]
      @survey.completion_message = params[:completion_message]
    end
    if params[:start_date_time]
      @survey.start_date_time = params[:start_date_time]
    end
    if params[:end_date_time]
      @survey.end_date_time = params[:end_date_time]
    end
    if params[:submit_text]
      @survey.submit_text = params[:submit_text]
    end
    if params[:submit_button_text]
      @survey.submit_button_text = params[:submit_button_text]
    end
    if params[:confirmation_text]
      @survey.confirmation_text = params[:confirmation_text]
    end
    if params[:preload]
      @survey.preload = params[:preload]
    end
  end

  def create
    org = current_user.organization
    survey_name = params[:survey][:name]
    survey_description = params[:survey][:description]
    survey_start_message = params[:survey][:start_message]
    survey_completion_message = params[:survey][:completion_message]
    survey_multiple_responses = params[:survey][:multiple_responses_allowed]
    survey_show_take_again = params[:survey][:show_take_again]
    survey_preload = params[:survey][:preload]
    keyword_ids = params[:keyword]
    survey_button_text = params[:survey][:submit_button_text]
    survey_submit_text = params[:survey][:submit_text]

    confirmation_text = params[:survey][:confirmation_text]
    survey_confirmation_text = !confirmation_text.empty? ? confirmation_text : nil

    # Format The Date Times
    survey_start_time = params[:survey][:start_date_time]
    survey_start_time = survey_start_date = Date.strptime(survey_start_time, '%m/%d/%Y')
    survey_start_time = Time.find_zone(current_user.organization.timezone).local(survey_start_time.year, survey_start_time.month, survey_start_time.day, 00, 00).utc

    survey_end_time = params[:survey][:end_date_time]
    survey_end_time = survey_end_date = Date.strptime(survey_end_time, '%m/%d/%Y')
    survey_end_time = Time.find_zone(current_user.organization.timezone).local(survey_end_time.year, survey_end_time.month, survey_end_time.day, 23, 59).utc

    error_occurred = false
    new_survey = nil
    ActiveRecord::Base.transaction do

      # First Create The Survey
      new_survey = Survey.new(name: survey_name, description: survey_description, start_message: survey_start_message, completion_message: survey_completion_message, start_date_time: survey_start_time, end_date_time: survey_end_time, organization_id: org.id, multiple_responses_allowed: survey_multiple_responses == "Yes" ? true : false, submit_text: survey_submit_text, submit_button_text: survey_button_text, confirmation_text: survey_confirmation_text, preload: survey_preload == "Yes" ? true : false, ordered_questions: true, show_take_again: survey_show_take_again == "Yes" ? true : false)

      if !new_survey.save
        flash[:failure] = "We could not create your survey.\n#{new_survey.errors.full_messages.join(",\n")}"
        error_occurred = true
        raise ActiveRecord::Rollback
      end

      # Second Create The Keyword
      for keyword_id in keyword_ids
        new_keyword_relationship = KeywordSurveyRelationship.new(keyword_id: keyword_id, survey_id: new_survey.id)

        if !new_keyword_relationship.save
          flash[:failure] = "We could not attach your survey to the keyword.\n#{new_keyword_relationship.errors.full_messages.join(",\n")}"
          error_occurred = true
          raise ActiveRecord::Rollback
        end
      end
    end

    # Process The State Of The Call
    if error_occurred
      redirect_to survey_new_path(name: survey_name, description: survey_description, start_message: survey_start_message, completion_message: survey_completion_message, start_date_time: survey_start_date, end_date_time: survey_end_date)
      return
    else
      redirect_to survey_questions_path(survey_id: new_survey.id)
      return
    end

  end

  def edit
    @current_organization = current_user.organization
    @survey = Survey.find_by_id(params[:survey_id])
    @keyword = @survey.keywords.first
  end

  def delete
    current_organization = current_user.organization
    survey = current_organization.surveys.find_by_id(params[:id])
    if !survey
      flash[:failure] = "We could not find the survey you are looking to delete."
      redirect_to survey_overview_path
      return
    else
      if survey.destroy
        flash[:success] = "Survey has been deleted."
      else
        flash[:failure] = "We could not delete the survey. #{survey.errors.full_messages.join(",")}"
      end
    end
  end

  def update
    survey = Survey.find_by_id(params[:survey][:survey_id])
    org = current_user.organization
    survey_name = params[:survey][:name]
    survey_description = params[:survey][:description]
    survey_start_message = params[:survey][:start_message]
    survey_completion_message = params[:survey][:completion_message]
    keyword_ids = params[:keyword]
    existing_keywords = survey.keywords.ids
    new_keywords = keyword_ids - existing_keywords
    deleted_keywords = existing_keywords - keyword_ids
    survey_show_take_again = params[:survey][:show_take_again]

    survey_multiple_responses = params[:survey][:multiple_responses_allowed]
    survey_preload = params[:survey][:preload]
    survey_button_text = params[:survey][:submit_button_text]
    survey_submit_text = params[:survey][:submit_text]
    survey_confirmation_text = params[:survey][:confirmation_text]

    # Format The Date Times
    survey_start_time = params[:survey][:start_date_time]
    survey_start_time = survey_start_date = Date.strptime(survey_start_time, '%m/%d/%Y')
    survey_start_time = Time.find_zone(current_user.organization.timezone).local(survey_start_time.year, survey_start_time.month, survey_start_time.day, 00, 00).utc

    survey_end_time = params[:survey][:end_date_time]
    survey_end_time = survey_end_date = Date.strptime(survey_end_time, '%m/%d/%Y')
    survey_end_time = Time.find_zone(current_user.organization.timezone).local(survey_end_time.year, survey_end_time.month, survey_end_time.day, 23, 59).utc

    survey.name = survey_name
    survey.description = survey_description
    survey.start_message = survey_start_message
    survey.completion_message = survey_completion_message
    survey.start_date_time = survey_start_time
    survey.end_date_time = survey_end_date
    survey.multiple_responses_allowed = survey_multiple_responses
    survey.show_take_again = survey_show_take_again
    survey.preload = survey_preload
    survey.submit_button_text = survey_button_text
    survey.submit_text = survey_submit_text
    survey.confirmation_text = !survey_confirmation_text.empty? ? survey_confirmation_text : nil

    if !survey.save
      flash[:failure] = "Could not update the survey. #{survey.errors.full_messages.join(",\n")}"
      redirect_to survey_edit_path(survey_id: survey.id)
      return
    else

      # Delete Keywords
      for keyword_id in deleted_keywords
        relationship = KeywordSurveyRelationship.find_by(survey_id: survey.id, keyword_id: keyword_id)
        if relationship
          relationship.destroy
        else
          flash[:failure] = "We could not remove the keyword with id #{keyword_id} from your survey."
          redirect_to survey_edit_path(survey_id: survey.id)
          return
        end
      end

      # Add New Keywords
      for keyword_id in new_keywords
        relationship = KeywordSurveyRelationship.new(survey_id: survey.id, keyword_id: keyword_id)
        if !relationship.save
          flash[:failure] = "We could not attach your survey to the keyword.\n#{relationship.errors.full_messages.join(",\n")}"
          redirect_to survey_edit_path(survey_id: survey.id)
          return
        end
      end

      flash[:success] = "Survey was updated!"
      redirect_to survey_overview_path
      return
    end

  end

  def questions
    survey_id = params[:survey_id]
    @survey = Survey.find_by_id(survey_id)

    if !@survey
      flash[:failure] = "We could not find the survey you were looking for."
      redirect_to survey_overview_path
      return
    end

    if @survey.ordered_questions
      @questions = @survey.survey_questions.order(:order)
    else
      @questions = @survey.survey_questions.order(:id)
    end

    @all_questions = SurveyQuestion.where(survey_id: current_user.organization.surveys.ids)
  end

  def new_question
    @survey = Survey.find_by_id(params[:survey_id])
    @question_type = params[:question_type]
  end

  def edit_question
    @question = SurveyQuestion.find_by_id(params[:question_id])
    @survey = Survey.find_by_id(@question.survey_id)
  end

  def update_import_questions
    @survey = Survey.find_by(id: params[:survey_id])
    @all_questions = SurveyQuestion.where(survey_id: current_user.organization.surveys.ids)

    if !params[:search].nil? && !params[:search].empty?
      @all_questions = @all_questions.search_terms(params[:search])
    end

    if !params[:category].nil? && !params[:category].empty?
      @all_questions = @all_questions.search_category(params[:category])
    end

    render partial: 'import_questions'
  end

  def question_create
    survey_id =  params[:survey_question][:survey_id]
    @survey = Survey.find_by_id(survey_id)
    if !@survey
      flash[:failure] = "We could not find the survey you were looking for."
      redirect_to survey_overview_path
      return
    end


    question_prompt = params[:survey_question][:question]
    question_type = params[:survey_question][:question_type]
    question_low_title = nil
    question_high_title = nil
    question_required = params[:survey_question][:required]
    question_detail = params[:survey_question][:detail]
    question_min = params[:survey_question][:min_range]
    question_max = params[:survey_question][:max_range]
    question_other = params[:survey_question][:allow_other]
    question_confirm_answer = params[:survey_question][:confirm_answer]

    if !question_other
      question_other = false
    end

    if !question_confirm_answer
      question_confirm_answer = false
    end

    error_status = false

    if @survey.ordered_questions
      questions_count = @survey.survey_questions.count

      if questions_count > 0
        last_increment = @survey.survey_questions.order(:order).last.order
    else
            last_increment = nil
      end
    end

    ActiveRecord::Base.transaction do
      new_question = SurveyQuestion.new(question: question_prompt, question_type: question_type,  survey_id: survey_id, required: question_required, detail: question_detail, order: last_increment.nil? ? last_increment : last_increment + 1, allow_other: question_other, max_range: question_max, min_range: question_min, confirm_answer: question_confirm_answer)

      if !new_question.save
        flash[:failure] = "We could not create the question.\n#{new_question.errors.full_messages.join(",\n")}"
        error_status = true
        raise ActiveRecord::Rollback
      end
      #validate date for date question

			if new_question.is_date?
				unless new_question.validate_date_string
					flash[:failure] = "We could not create the question.\n#{new_question.errors.full_messages.join(",\n")}"
        	error_status = true
					raise ActiveRecord::Rollback
        end
			end

      # Handle Multiple Choice

      if question_type.to_i == 2
        question_mcs = params[:mc_answers]
        question_mcs_array = question_mcs.split(",")

        for mc in question_mcs_array
          new_mc_record = SurveyMultipleChoice.new(choice_item: mc, survey_question_id: new_question.id)
          if !new_mc_record.save
            flash[:failure] = "We could not create the multiple choice answers.\n#{new_mc_record.errors.full_messages.join(",\n")}"
            error_status = true
            raise ActiveRecord::Rollback
          end
        end

      end

    end

    if !error_status
      flash[:success] = "Question was added to the survey!"
    end
    redirect_to survey_questions_path(survey_id: survey_id)
    return

  end

  def question_duplicate
    survey_id =  params[:survey_id]
    survey = Survey.find_by_id(survey_id)
    if !survey
      flash[:failure] = "We could not find the survey you were looking for."
      redirect_to survey_overview_path
      return
    end

    existing_question_id = params[:existing_question_id]
    existing_question = SurveyQuestion.find_by_id(existing_question_id)
    if !existing_question
      flash[:failure] = "We could not find the survey question you were wanting to import."
      redirect_to survey_questions_path(survey_id: survey_id)
      return
    end

    question_prompt = existing_question.question
    question_type = existing_question.question_type
    question_low_title = existing_question.min_range
    question_high_title = existing_question.max_range
    question_required = existing_question.required
    question_detail = existing_question.detail
    question_other = existing_question.allow_other
    question_max = existing_question.max_range
    question_min = existing_question.min_range
    question_confirm_answer = existing_question.confirm_answer

    error_status = false

    if survey.ordered_questions
      questions_count = survey.survey_questions.count
      last_increment = questions_count == 0 ? nil : survey.survey_questions.order(:order).last.order
    end

    ActiveRecord::Base.transaction do
      new_question = SurveyQuestion.new(question: question_prompt, question_type: question_type, survey_id: survey_id, required: question_required, detail: question_detail, order: last_increment.nil? ? last_increment : last_increment + 1, allow_other: question_other, max_range: question_max, min_range: question_min, confirm_answer: question_confirm_answer)

      if !new_question.save
        flash[:failure] = "We could not create the question.\n#{new_question.errors.full_messages.join(",\n")}"
        error_status = true
        raise ActiveRecord::Rollback
      end

      # Handle Multiple Choice

      if question_type.to_i == 2
        for mc in existing_question.survey_multiple_choices
          new_mc_record = SurveyMultipleChoice.new(choice_item: mc.choice_item, survey_question_id: new_question.id)
          if !new_mc_record.save
            flash[:failure] = "We could not create the multiple choice answers.\n#{new_mc_record.errors.full_messages.join(",\n")}"
            error_status = true
            raise ActiveRecord::Rollback
          end
        end

      end

    end

    if !error_status
      flash[:success] = "Question was added to the survey!"
    end
    redirect_to survey_questions_path(survey_id: survey_id)
    return

  end

  def question_delete
    survey_id = params[:survey_id]
    question_id = params[:question_id]
    question = SurveyQuestion.find_by_id(question_id)

    if !question
      flash[:failure] = "We could not find the question you are looking to delete."
    else
      if question.destroy
        flash[:success] = "Question has been deleted from survey."
      else
        flash[:failure] = "We could not delete the question. #{question.errors.full_messages.join(",")}"
      end
    end

    redirect_to survey_questions_path(survey_id: survey_id)
    return
  end

  def question_update
    question_id = params[:survey_question][:question_id]
    question_prompt = params[:survey_question][:question]
    question_required = params[:survey_question][:required]
    question = SurveyQuestion.find_by_id(question_id)
    question_detail = params[:survey_question][:detail]
    question_min = params[:survey_question][:min_range]
    question_max = params[:survey_question][:max_range]
    question_other = params[:survey_question][:allow_other]
    question_confirm_answer = params[:survey_question][:confirm_answer]
    question_archive = params[:survey_question][:archive]

    if question
      if question_prompt
        question.question = question_prompt
      end

      if question_other
        question.allow_other = question_other
      end

      if question_detail
        question.detail = question_detail
      end

      if question_min
        question.min_range = question_min
      end

      if question_max
        question.max_range = question_max
      end

      if question_confirm_answer
        question.confirm_answer = question_confirm_answer
      end

      if question_required
        question.required = question_required
      end

      if question_archive == "1"
        question.archive = question_archive
        question.required = false
      else
        question.archive = question_archive
      end


      if question.is_rating?
        question_low_title = params[:survey_question][:min_range]
        question_high_title = params[:survey_question][:max_range]

        if question_low_title
          question.min_range = question_low_title
          question.max_range = question_high_title
        end
      end

      if question.is_mc?
        question_mcs = params[:mc_answers]
        if !question_mcs || question_mcs.empty?
          flash[:failure] = "You must provide answers for the drop down questions."
          redirect_to survey_questions_path(survey_id: params[:survey_question][:survey_id])
          return
        end
        question_mcs_array = question_mcs.split(",")
        current_mcs = question.survey_multiple_choices.pluck("choice_item")
        new_mcs =  question_mcs_array - current_mcs
        deleted_mcs = current_mcs - question_mcs_array



        # Delete the MCS
        for mcs in deleted_mcs
          delete_mcs = question.survey_multiple_choices.find_by(choice_item: mcs)
          if delete_mcs
            delete_mcs.destroy
          end
        end

        for mc in new_mcs
          new_mc_record = SurveyMultipleChoice.new(choice_item: mc, survey_question_id: question.id)
          if !new_mc_record.save
            flash[:failure] = "We could not create the drop downanswers.\n#{new_mc_record.errors.full_messages.join(",\n")}"
            redirect_to survey_questions_path(survey_id: params[:survey_question][:survey_id])
            return
          end
        end
      end


    else
      flash[:failure] = "Failed to find the question #{question_id}."
      redirect_to survey_questions_path(survey_id: params[:survey_question][:survey_id])
      return
    end

    if !question.save
      flash[:failure] = "Failed to update question #{question.question}.\n#{question.errors.full_messages.join(",\n")}"
    else
      flash[:success] = "Survey question successfully updated."
    end

    redirect_to survey_questions_path(survey_id: params[:survey_question][:survey_id])
    return

  end

  def show
    if params[:id]
      survey_id = params[:id]
    else
      survey_id = params[:survey_id]
    end
    @contact_id = params[:contact_id]
    @survey = Survey.find_by_id(survey_id)

    if @survey
      @organization = @survey.organization
      if !@survey.multiple_responses_allowed
        responses = @survey.survey_responses.where(contact_id: @contact_id)
        if !responses.empty? && !@survey.preload && @contact_id != "0"
          redirect_to survey_completed_path(id: survey_id)
          return
        end
      end

      if @survey.preload
        last_completed_survey = SurveyResponse.where(survey: survey_id, contact_id: @contact_id).last
        @survey_answers = last_completed_survey ? last_completed_survey.survey_answers : nil
      end

      if @survey.ordered_questions
        @questions = @survey.survey_questions.order(:order).where(archive: false)
      else
        @questions = @survey.survey_questions.order(:id).where(archive: false)
      end
    end

    @transition = true
    render layout: "empty"
  end

  def preview
    survey_id = params[:id]
    mobile_preview = params[:mobile_preview]
    @contact_id = params[:contact_id]
    @survey = Survey.find_by_id(survey_id)
    @organization = @survey.organization
    if !@survey.multiple_responses_allowed
      responses = @survey.survey_responses.where(contact_id: @contact_id)
      if !responses.empty?
        redirect_to survey_completed_path(id: survey_id, contact_id: @contact_id)
        return
      end
    end
    if @survey.ordered_questions
      @questions = @survey.survey_questions.order(:order).where(archive: false)
    else
      @questions = @survey.survey_questions.order(:id).where(archive: false)
    end
    render layout: "empty"
  end

  def submit
    survey_id = params[:survey_id]
    contact_id = params[:contact_id]
    survey = Survey.find_by_id(survey_id)

    organization = survey.organization
    if !survey
      flash[:failure] = "The survey is no longer found. Please contact the administration of your survey."
      redirect_to survey_show_path(id: survey_id, contact_id: contact_id)
      return
    end

    contact = organization.contacts.find_by_id(contact_id)
    if !contact && contact_id != "0"
      flash[:failure] = "We could not find you as a contact to the organization owning this survey. Please opt in to the survey keyword."
      redirect_to survey_show_path(id: survey_id, contact_id: contact_id)
      return
    end

    # Check To See If Response Is Allowed
    if !survey.multiple_responses_allowed && contact_id != "0" && !survey.preload
      existing_responses = survey.survey_responses.where(contact_id: contact_id)
      if !existing_responses.empty?
        flash[:failure] = "Only one response is allowed."
        redirect_to survey_show_path(id: survey_id, contact_id: contact_id)
        return
      end
    end

    # Process The Questions
    questions = survey.survey_questions.where(archive: false)
    error_occurred = false
    survey_response = contact_id != "0" ? SurveyResponse.find_by(survey_id: survey_id, contact_id: contact_id) : nil

    ActiveRecord::Base.transaction do
      # Create The Response Record unless there's already one and multiple responses are not allowed
      if survey.multiple_responses_allowed || !survey_response
        survey_response = SurveyResponse.new(survey_id: survey_id, contact_id: contact_id, contact_number: !contact.nil? ? contact.cell_phone : "5555555555")

        if !survey_response.save
          error_occurred = true
          flash[:failure] = "Failed to create a response to the survey. Please contact customer support at support@mobilizecomms.com. #{survey_response.errors.full_messages}"
          raise ActiveRecord::Rollback
        end
      end

      for question in questions
        if !question.archive && question.check_validations(params)
          survey_result = params["#{question.id}"]
          if ( survey_result.nil? || survey_result.blank? ) && question.required
            error_occurred = true
            flash[:failure] = "You have to provide an answer to all required questions."
            raise ActiveRecord::Rollback
          end

          # validate signature
          if question.is_signature? && params["#{question.id}-confirm"]["confirm"] == "0"
            error_occurred = true
            flash[:failure] = "You have to confirm your digital signature."
            raise ActiveRecord::Rollback
          end
          #validate date answers
          if question.is_date?
            date = Date.strptime(survey_result, '%m/%d/%Y') rescue nil
            min_range = Date.strptime(question.min_range, '%m/%d/%Y') rescue nil
            max_range = Date.strptime(question.max_range, '%m/%d/%Y') rescue nil
            if date.nil? || (min_range > date rescue false)
              error_occurred = true
              flash[:failure] = "You have to provide a valid date to all required questions."
              raise ActiveRecord::Rollback
            elsif date.nil? || (max_range < date rescue false)
              error_occurred = true
              flash[:failure] = "You have to provide a valid date to all required questions."
              raise ActiveRecord::Rollback
            end
          end

          old_answer = SurveyAnswer.find_by(survey_response_id: survey_response.id, survey_question_id: question.id)

          #validate phone answer

          if question.is_phone_number? && !Phonelib.valid?(survey_result)
            error_occurred = true
            flash[:failure] = "You must provide a valid Phone Number"
            raise ActiveRecord::Rollback
          end

          if question.is_phone_number? && Phonelib.valid?(survey_result)
            survey_result = Phonelib.parse(survey_result).sanitized
          end

          if !old_answer || contact_id == "0"
            new_answer = SurveyAnswer.new(survey_response_id: survey_response.id, survey_question_id: question.id, answer: survey_result)
          else
            old_answer.answer = survey_result
            new_answer = old_answer
          end

          if !new_answer.save
            error_occurred = true
            flash[:failure] = "Failed to create a response to the survey. Please contact customer support at support@mobilizecomms.com. #{new_answer.errors.full_messages}"
            raise ActiveRecord::Rollback
          end

        end
      end

    end

    # Process The State Of The Call
    if error_occurred
      redirect_to survey_show_path(id: survey_id, contact_id: contact_id)
      return
    end

    # Send Survey Completion Confirmation Text to Contact
    credits_left = organization.credits_left
    text_time = Time.now.in_time_zone(organization.timezone).strftime('%F %H:%M:%S')
    completed_survey_link = "messaging.mobilizeus.com#{survey_completed_path(id: survey.id, contact_id: contact_id)}"
    confirmation_text = survey.confirmation_text
    confirmation_message = "#{text_time} #{confirmation_text} #{completed_survey_link}"

    if !confirmation_text.nil? && !confirmation_text.empty? && contact_id != "0" && credits_left > 0
      # charge rate based on confirmation text and does not include the time or survey link
      rate = helpers.sms_rate_check(survey.confirmation_text)
      confirm_blast = Blast.new(
        user_id: 0,
        organization: organization,
        active: true,
        keyword_id: survey.keywords.first.id,
        keyword_name: survey.keywords.first.name,
        message: confirmation_message,
        sms: true,
        send_date_time: Time.now,
        contact_count: 1,
        cost: rate,
        rate: rate
      )

      if !confirm_blast.save
        # error notification
        HoneyBadger.notify("Error sending survey completion confirmation text | organization: #{organization.id}, survey: #{survey.id}")
      else

        blast_contact_relationship = BlastContactRelationship.new(blast: confirm_blast, status: "Sent", contact_id: contact_id)

        if !blast_contact_relationship.save
          # error notification
          HoneyBadger.notify("Error sending survey completion confirmation text | blast: #{confirm_blast.id}, contact: #{contact_id}")
        else
          helpers.set_blast_job(survey.organization.id, confirm_blast, nil)
        end

      end
    end

    redirect_to survey_completed_path(id: survey_id,  contact_id: contact_id)
    return
  end

  def completed
    @survey = Survey.find_by_id(params[:id])
    @contact = Contact.find_by_id(params[:contact_id])
    @survey_response = @survey.survey_responses.where(contact_id: params[:contact_id]).order("created_at DESC").first
    if @survey_response
      @survey_answers = @survey_response.survey_answers
    else
      flash["alert"] = "We could not find your response to this survey. Please make sure the survey submitted."
      redirect_to survey_show_path(survey_id: params[:id], contact_id: params[:contact_id])
      return
    end

    render layout: "empty"
  end

  def save_question_order
    survey = Survey.find_by_id(params[:survey_id])
    if !survey.survey_questions.pluck(:validation_array).flatten.empty?
      flash["alert"] = "Cannot reorder questions when validations are present. You must remove them first."
      redirect_to survey_questions_path(survey_id: survey.id)
      return
    end
    question_order = params[:question_order]
    question_order = question_order.split(",")
    if !question_order
      flash["alert"] = "Please provide a question order."
      redirect_to survey_questions_path(survey_id: survey.id)
      return
    end
    error_occured = false
    error_message = ""
    ActiveRecord::Base.transaction do
      survey.ordered_questions = true
      if !survey.save
        error_occured = true
        error_message = "Failed to save the question order for your survey. #{survey.errors.full_messages.join(" ")}"
        raise ActiveRecord::Rollback
      end

      # Process The Question Order
      i = 1
      for question_id in question_order
        question_record = survey.survey_questions.find_by_id(question_id)
        if !question_record
          error_occured = true
          error_message = "We could not find one of your questions."
          raise ActiveRecord::Rollback
        end

        question_record.order = i
        if !question_record.save
          error_occured = true
          error_message = "We could save your question order. #{question_record.errors.full_messages.join(" ")}"
          raise ActiveRecord::Rollback
        end

        i += 1
      end

    end

    if error_occured
      flash[:alert] = error_message
    else
      flash[:success] = "Your question order has been saved!"
    end

    redirect_to survey_questions_path(survey_id: survey.id)
    return
  end

  def responses_export
    organization = current_user.organization
    survey = organization.surveys.find_by_id(params[:id])


    if !params[:start_date].blank? && !params[:end_date].blank?
      start_date = Date.strptime(params[:start_date], "%m/%d/%Y")
      end_date = Date.strptime(params[:end_date], "%m/%d/%Y")
    else
      start_date = survey.start_date_time
      end_date = survey.end_date_time
    end


    # Create The Job
    SurveyExportJob.perform_async(survey.id, current_user.id, start_date, end_date)

    flash["success"] = "Your Survey Responses Will Be Emailed Once We Create The File For You To Download."

    redirect_to survey_view_path(id: params[:id])

  end

  def answer_table
    organization = current_user.organization
    answers = SurveyAnswer.where(survey_question: params[:question]).order('created_at DESC')

    @choice_answers = answers.map do |answer|
      response = SurveyResponse.find_by_id(answer.survey_response_id)
      survey_mc = SurveyMultipleChoice.where(survey_question_id: answer.survey_question_id).find_by_id(answer.answer)
      {
        id: answer.id,
        response_id: answer.survey_response_id,
        phone: response.contact_id == '0' ? response.contact_number : 'Entered Manually',
        created_at: answer.created_at.in_time_zone(organization.timezone).strftime('%m/%d/%Y at %H:%M %p %Z'),
        answer: survey_mc ? survey_mc.choice_item : answer.answer
      }
    end
    @pagy_a, @q_answers = pagy(answers, page_param: :q_answers)
    render partial: "answer_table"
  end

  def answers_upload
    @survey = Survey.find_by(id: params[:survey_id])
    @survey_answer_upload = SurveyAnswerUpload.find_by(id: params[:sa_upload_id])
    @questions = @survey.survey_questions.pluck(:question)
    if @survey_answer_upload
      @uploaded_headers = open(@survey_answer_upload.file.url) {|csv| csv.readline.gsub("\n",'').split(',')}
    end
  end

  def upload
    sau = SurveyAnswerUpload.new(file: params[:survey_answer_upload][:file], organization: current_user.organization, user: current_user)
    if !sau.save
      flash[:alert] = sau.errors.full_messages.join("\n")
      redirect_to survey_answers_upload_path
      return
    else
      # redirect_to contacts_upload_overview_path(upload_id: @cu.id)
      redirect_to survey_answers_upload_path(survey_id: params[:survey_id], sa_upload_id: sau.id)
      return
    end
  end

  def upload_headers
    survey = Survey.find_by(id: params[:survey_id])
    questions = survey.survey_questions
    sau = SurveyAnswerUpload.find_by(id: params[:sa_upload_id])
    # send to job ?
      # create new survey_answer
    csv_text = open(sau.file.url)
    CSV.parse(csv_text, :headers => true, encoding:'iso-8859-1:utf-8').map do |row|

      survey_response = SurveyResponse.new(survey_id: survey.id, contact_id: 0, contact_number: "From CSV Data")
      if !survey_response.save
        survey_response = SurveyResponse.find_by(id: 0)
      end

      questions.each do |q|
        header = params[q.question]
        answer = row[header.delete("\r\n")]
        if answer
          survey_answer = SurveyAnswer.new(survey_response_id: survey_response.id, survey_question_id: q.id, answer: answer)

          if !survey_answer.save
            # error reporting
            flash[:failure] = "We could not create your survey.\n#{new_survey.errors.full_messages.join(",\n")}"
            error_occurred = true
          end
        end
      end
    end

    flash["success"] = "Survey data entered successfully"
    redirect_to survey_view_path(id: survey.id)
    return
  end

  def individual_response
    @response = SurveyResponse.find_by_id(params[:id])
    @contact = Contact.find_by_id(@response.contact_id)
  end

  private

  def allow_iframe
    response.headers.except! 'X-Frame-Options'
  end

  def body(survey)
    puts "Survey: #{survey.survey_responses.count}"
    header = ["Response Id", "Contact Id", "Contact Number", "Created At"]
    if survey.ordered_questions
        survey_questions = survey.survey_questions.order(:order).map do |q|
          c = q.archive ? " (Hidden/Archived)" : ""
          q.question + c
        end
        header = header + survey_questions
        ordered_questions = survey.survey_questions.order(:order)
    else
        survey_questions = survey.survey_questions.map do |q|
          c = q.archive ? " (Hidden/Archived)" : ""
          q.question + c
        end
        header = header + survey_questions
        ordered_questions = survey.survey_questions.order(:id)
    end

    header_added = false

    Enumerator.new do |yielder|
      if !header_added
        yielder << CSV.generate_line(header)
        header_added = true
      end
      survey.survey_responses.find_each do |resp|


        puts "survey item: #{resp.id}"

        row = [resp.id, resp.contact_id, resp.contact_number, resp.created_at.in_time_zone(survey.organization.timezone)]
        ordered_questions = survey.survey_questions.order(:order)
        for question in ordered_questions
            answer = survey.survey_answers.find_by(survey_question_id: question.id, survey_response_id: resp.id)
            if answer
                if question.is_mc?
                    if question.survey_multiple_choices.find_by_id(answer.answer)
                        row.push(question.survey_multiple_choices.find_by_id(answer.answer).choice_item)
                    else
                        row.push(answer.answer)
                    end
                else
                    row.push(answer.answer)
                end
            else
                row.push("")
            end
        end
        yielder << CSV.generate_line(row)

      end
    end
  end

end
