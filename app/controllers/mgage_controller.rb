class MgageController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :notification_check
  skip_before_action :active_billing_status
  protect_from_forgery with: :null_session
  
  layout 'empty'
  

  def mgage_dr
    head :ok

    carrier = params[:carrier]
    status = params[:status]
    status_code = params[:status_code]
    message_id = params[:message_id]
    cell_phone = params[:device_address]

    # Search for the blast relationship that contains the message_id 
    bcr = BlastContactRelationship.find_by(message_id: message_id)
    if bcr 
      if ["110", "250", "260", "270", "275", "280", "290"].include?(status_code) # Failures
        bcr.status = "Failed"
      elsif ["131", "132", "133"].include?(status_code) # Profanity & Profane Content
        bcr.status = "Failed"
      elsif ["7", "30", "124", "210", "10", "5", "6"].include?(status_code) # Processing
        bcr.status = "Processing"
      elsif ["40", "130", "200"].include?(status_code) # Delivered
        bcr.status = "Delivered"
      elsif ["129"].include?(status_code) # Landline
        bcr.status = "Landline"
      else
        bcr.status = "Sent"
      end 
      bcr.mgage_status = status 
      bcr.mgage_status_code = status_code
      if !bcr.save 
        Honeybadger.notify("Failed to update a blast contact relationship with id: #{bcr.id}. | #{bcr.errors.full_messages}", class_name: "Mgage Controller -> DR", error_message: bcr.errors.full_messages, parameters: params)
      end
    end
  end

  def mo #mGage Replies 
    head :ok

    logger.info("------> MO Params: #{params}")
    logger.info("-----> REQUEST: #{request.fullpath}")
    logger.info("---> body #{request.body}")
    logger.info("-----> RAW: #{request.raw_post}")
    logger.info("-----> Request Params: #{request.query_parameters}")
    device_id = params[:device_address]
    inbound_number = params[:inbound_address]
    message_type = params[:channel]
    message = params[:message]
    mgage_message_id = params[:message_id]
    message_subid = params[:message_subid] # ordering long messages 

    MoJob.perform_async(device_id, inbound_number, message_type, message, mgage_message_id, message_subid, "mgage")
    

  end

end
