class QueueController < ApplicationController
  include Pagy::Backend

  before_action :authenticate_user!

  $list = []

  def overview
    org_queues = CustomQueue.where('end_date >= CURRENT_DATE', organization: current_organization).order(:created_at)

    if !params[:search]
      @pagy, @queues = pagy(org_queues, items: 25)
      $list = @queues
    else
      search_text = params[:search]
      search_text = search_text.gsub(' ', '')
      @pagy, @queues = pagy(org_queues.where('name ILIKE :search', search: "%#{search_text}%").order(:created_at))
      $list = @queues
    end
  end

  def gen_delete (list)
    if !list.empty?
      success_deleted = []
      success_deleted_res = ""
      list.each do |id|
        queue_to_delete = CustomQueue.find_by_id(id)
        success_deleted.push queue_to_delete.name
        queue_to_delete.destroy
      end
      success_deleted.each do |j|
        success_deleted_res += j + ",\n"
      end
      if !success_deleted.empty?
        flash[:success] = success_deleted_res + " successfully deleted."
      end
    else
      flash[:alert] = "No queues to delete!!!!!"
    end
  end

  def delete
    if !params[:param].present?
    # if params[:param].nil?
      ids = $list.pluck(:id)
      gen_delete(ids)
    else
      param = params[:param]
      gen_delete(param)
    end
  end

  def gen_empty (list)
    if !list.empty?
      failed_p_ones = []
      success_p_ones = []
      failed_p_res = ""
      success_p_res = ""
      list.each do |id|
        psrqr = SurveyResponseQueueRelationship.where(custom_queue_id: id)
        if !psrqr.empty?
          has_relation = CustomQueue.find_by_id(id).name
          success_p_ones.push has_relation
          psrqr.each do |j|
            j.destroy
          end
        else
          failed_p_ones.push id
          p failed_p_ones
        end
      end
      success_p_ones.each do |j|
        success_p_res += j + ",\n"
      end
      failed_p_ones.each do |i|
        pfq = CustomQueue.find_by_id(i).name
        failed_p_res += pfq + ",\n"
      end
      if !success_p_res.empty?
        flash[:success] = success_p_res + " successfully emptied."
      end
      if !failed_p_ones.empty?
        flash[:alert] = failed_p_res + " no responses, nothing to empty."
      end
    else
      flash[:alert] = "Surveys have no responses to empty!"
    end
  end

  def empty
    if !params[:param].present?
    # if params[:param].nil?
      ids = $list.pluck(:id)
      gen_empty(ids)
    else
      $list = params[:param]
      param = $list
      gen_empty(param)
    end
  end

  def create
    logger.info("Executing Queue Create Method")
    #require binding.pry; binding.pry
    queue_name = params[:custom_queue][:name]
    queue_description = params[:custom_queue][:description]
    survey_ids = params[:survey]
    queue_capacity = params[:custom_queue][:capacity]
    adjust_capacity_on_completion = params[:custom_queue][:adjust_capacity_on_completion]

    queue_start_date = params[:custom_queue][:start_date]
    queue_start_date = Date.strptime(queue_start_date, '%m/%d/%Y')
    queue_start_date = Time.find_zone(current_user.organization.timezone).local(queue_start_date.year, queue_start_date.month, queue_start_date.day, 00, 00).utc

    queue_end_date = params[:custom_queue][:end_date]
    queue_end_date = Date.strptime(queue_end_date, '%m/%d/%Y')
    queue_end_date = Time.find_zone(current_user.organization.timezone).local(queue_end_date.year, queue_end_date.month, queue_end_date.day, 00, 00).utc

    queue_start_time = params[:custom_queue][:start_time]
    queue_end_time = params[:custom_queue][:end_time]

    error_occurred = false
    new_queue = nil
    ActiveRecord::Base.transaction do

      new_queue = CustomQueue.new(name: queue_name, description: queue_description, organization: current_organization, capacity: queue_capacity, adjust_capacity_on_completion: adjust_capacity_on_completion, start_date: queue_start_date, end_date: queue_end_date, start_time: queue_start_time, end_time: queue_end_time)

      if !new_queue.save!
        flash[:failure] = "We could not create your queue."
        error_occurred = true
        raise ActiveRecord::Rollback
      end

      # Second Create The SurveyQueue Relationship
      for survey_id in survey_ids
        new_survey_relationship = SurveyQueueRelationship.new(custom_queue_id: new_queue.id, survey_id: survey_id)

        if !new_survey_relationship.save
          flash[:failure] = "We could not attach your survey to the queue.\n#{new_survey_relationship.errors.full_messages.join(",\n")}"
          error_occurred = true
          raise ActiveRecord::Rollback
        end
      end

      if !new_survey_relationship.save!
        flash[:failure] = "SurveyQueueRelationship could not be created."
        error_occurred = true
        raise ActiveRecord::Rollback
      end

    end

    # Process The State Of The Call
    if error_occurred
      redirect_to queue_new_path(name: queue_name, description: queue_description, organization: current_organization, capacity: queue_capacity, adjust_capacity_on_completion: adjust_capacity_on_completion, start_date: queue_start_date, end_date: queue_end_date, start_time: queue_start_time, end_time: queue_end_time)
      return
    else
      flash[:notice] = "Queue " + queue_name + " was succesfully created."
      redirect_to queue_view_path(queue_id: new_queue.id)
      return
    end

  end

  def new
    logger.info("Entering Queue New Method")

    @current_organization = current_user.organization
    @queue = CustomQueue.new
    if params[:name]
      @queue.name = params[:name]
    end
    if params[:description]
      @queue.description = params[:description]
    end
    if params[:survey]
      @queue.survey = params[:survey]
    end
    if params[:start_date]
      @queue.start_date = params[:start_date]
    end
    if params[:end_date]
      @queue.end_date = params[:end_date]
    end
    if params[:start_time]
      @queue.start_time = params[:start_time]
    end
    if params[:end_time]
      @queue.end_time = params[:end_time]
    end
    if params[:capacity]
      @queue.capacity = params[:capacity]
    end
    if params[:adjust_capacity_on_completion]
      @queue.adjust_capacity_on_completion = params[:adjust_capacity_on_completion]
    end
  end

  def new_review
    logger.info("PARAMS: #{params}")
  end

  def view
    @queue_id = params[:queue_id]
    @queue = CustomQueue.find_by_id(@queue_id)
    @pagy, @queue_appointments = pagy(SurveyResponseQueueRelationship.where(custom_queue: @queue), items: 25)
  end

  def complete_appointment
    queue_appointment = SurveyResponseQueueRelationship.find_by_id(params[:id])
    queue_id = queue_appointment.custom_queue_id
    queue_appointment.completed = true
    if !queue_appointment.save
      flast[:alert] = queue_appointment.errors.full_messages
      redirect_to queue_view_path(queue_id: queue_id)
      return
    else
      flash[:success] = "Queue appointment completed!"
      redirect_to queue_view_path(queue_id: queue_id)
      return
    end
  end

end
