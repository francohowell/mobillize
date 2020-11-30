class ChatController < ApplicationController
  before_action :authenticate_user!

  include Pagy::Backend

  def overview
    @organization = current_user.organization
    if @organization.plan.name == "Pay As You Go"
      redirect_to root_path
      return
    end
    @long_code = @organization.phone_numbers.where(long_code: true).first
    if !@long_code
      redirect_to chat_confirm_activate_path
      return
    end
    @pagy, @chats = pagy(@organization.chats.select("DISTINCT ON (contact_id) *, created_at").where.not(contact_id: nil).order("contact_id, created_at DESC"), items: 25)
  end

  def confirm_activate
    org = current_user.organization

    ## Get One To One Add On
    @add_on = AddOn.find_by_name("One-To-One")
  end

  def activate_chat
    org = current_user.organization

    ###--> Assign new number
    tms = TwilioMasterService.new

    if org.state_providence
      number, number_results = tms.find_local_number(org.state_code)
    else
      number, number_results = tms.find_us_number
    end

    if number_results[:failed].present?
      logger.error("Failed to obtain a new long code for organization #{org.id}")
      logger.error(number_results[:failed])
      flash[:alert] = "An error has occured while activating your One To One feature. Please contact customer support."
      redirect_to chat_overview_path
      return
    end

    purchased_number, purchased_number_result = tms.purchase_number(number.phone_number)
    if purchased_number_result[:failed].present?
      logger.error("Failed to purchase a new long code for organization #{org.id}")
      logger.error(purchased_number_result[:failed])
      flash[:alert] = "An error has occured while activating your One To One feature. Please contact customer support."
      redirect_to chat_overview_path
      return
    end

    new_long_code_relationship = OrganizationPhoneRelationship.new(organization_id: org.id, phone_number_id: purchased_number.id, mass_outgoing: false)
    if !new_long_code_relationship.save
      logger.error("Failed to setup a new relationship with long code for organization #{org.id} and number #{purchased_number.id}")
      logger.error(new_long_code_relationship.erros.full_messages)
      flash[:alert] = "An error has occured while activating your One To One feature. Please contact customer support."
      redirect_to chat_overview_path
      return
    end

    flash[:success] = "Your One To One feature has been activated!"
    redirect_to chat_overview_path
    return
  end

  def feed
    chat_id = params[:chat_id]
    contact_id = params[:contact_id]

    @organization = current_user.organization
    @long_code = @organization.phone_numbers.where(long_code: true).first
    @contact = nil
    if chat_id
      @chat = Chat.find_by_id(chat_id)
      if @chat.contact_id
        @contact = Contact.find_by_id(@chat.contact_id)
      end
      # @chat_history = Chat.where("chats.from IN ? AND chats.to IN ?", [@chat.to, @chat.from], [@chat.to, @chat.from])
      @chat_history = Chat.where(to: [@chat.to, @chat.from], from: [@chat.to, @chat.from])
    elsif contact_id
      @chat = Chat.new
      @contact = Contact.find_by_id(contact_id)
      @chat_history = Chat.where("chats.from = ? OR chats.to = ?", @contact.cell_phone, @contact.cell_phone)
    end

     ## AJAX RESPONSE ##
     if request.xhr?
      respond_to do |format|
        format.json {
          render json: {chat_history: @chat_history}
        }
      end
    end
  end

  def feed_check
    contact_id = params[:contact_id]
    @organization = current_user.organization
    previous_ajax_datetime = params[:previous_date_time]
    last_ajax_datetime = params[:new_date_time_check]
    @long_code = @organization.phone_numbers.where(long_code: true).first
    @chat_history = []
    if last_ajax_datetime
      last_ajax_datetime = Time.at(last_ajax_datetime.to_i / 1000.0)
      if previous_ajax_datetime
        previous_ajax_datetime =  Time.at(previous_ajax_datetime.to_i / 1000.0)
        @contact = Contact.find_by_id(contact_id)
        @chat_messages_in_date_range = Chat.where("(chats.from = ? OR chats.to = ?) AND created_at BETWEEN ? AND ? ", @contact.cell_phone, @contact.cell_phone, previous_ajax_datetime, last_ajax_datetime)
        if !@chat_messages_in_date_range.empty?
          @chat_history = Chat.where("chats.from = ? OR chats.to = ?", @contact.cell_phone, @contact.cell_phone).order("created_at")
        end
      end
    end

    # Update Last Inbound As Read
    if !@chat_history.empty?
      new_chats_inbound = @chat_history.where(inbound: true, inbound_read: false).order("created_at DESC")
      if new_chats_inbound
        new_chats_inbound.each do |chat|
          chat.update(inbound_read: true)
          if !chat.save
            Honeybadger.notify("Failed to update a chat inbound read status: #{last_chat_inbound.id}. | #{last_chat_inbound.errors.full_messages}", class_name: "Chat Controller -> Feed Check", error_message: last_chat_inbound.errors.full_messages)
          end
        end
      end
    end

    if !@chat_history.empty?
      render partial: "chat_area"
    end

    ## AJAX RESPONSE ##
    # if request.xhr?
    #   respond_to do |format|
    #     format.json {
    #       render json: {chat_history: @chat_history}
    #     }
    #   end
    # end
  end

  def message_check
      message_text = params[:message]
      message_service = MessageService.new(message_text, nil)
      ## AJAX RESPONSE ##
      if request.xhr?
        respond_to do |format|
          format.json {
            render json: {rate: message_service.sms_rate}
          }
        end
      end
  end

  def send_chat
    organization = current_user.organization
    message = params[:message]

    twilio_format_contact = "#{"+"}#{params[:cell_phone]}"

    phone = organization.phone_numbers.where(long_code: true).first
    if !phone.real.match(/\+/)
      twilio_format_from = "#{"+"}#{phone.real}"
    else
      twilio_format_from = phone.real
    end

    twilio_manager = TwilioMasterService.new()

    # Get Account Usage
    account_usage = organization.current_credit_usage
    if organization.annual_credits <= account_usage
      flash[:alert] = "You do not have enough credits for the chat. Please upgrade you account."
      return
    end
    remaining_credits = organization.credits_left

    # SMS Filtering
    message_service = MessageService.new(message, nil)

    # Determine if account has enough credits for the message
    if remaining_credits < message_service.sms_rate
      flash[:alert] = "You do not have enough credits for the chat. Please upgrade you account."
      return
    end

    # possibly where the logic for contacts that are not active don't receive one to one goes
    contact_id = nil
    if params[:contact_id]
      contact = Contact.find_by_id(params[:contact_id])
      if contact
        contact_id = contact.id
      end
    end

    previous_chat = organization.chats.where(to: params[:cell_phone])
    if previous_chat.empty?
      # Create New Chat
      welcome_text = "Welcome. This is a private message line between you and #{organization.name}. This is automated message and all data rates apply."
      welcome_message_service = MessageService.new(welcome_text, nil)

      # Determine if account has enough credits for the message and the welcome message
      if remaining_credits < (message_service.sms_rate + welcome_message_service.sms_rate)
        flash[:alert] = "You do not have enough credits for the chat. Please upgrade you account."
        return
      end

      welcome_chat = Chat.new(organization_id: organization.id, message_id: 0, message: welcome_text, to: params[:cell_phone], from: phone.real, contact_id: contact_id, rate: welcome_message_service.sms_rate)
      if welcome_chat.save
        twilio_manager.send_direct_message( twilio_format_from, twilio_format_contact, welcome_text)
      else
        flash[:alert] = "Failed to send your response. Please try again."
        return
      end
    end

    result = twilio_manager.send_direct_message( twilio_format_from, twilio_format_contact, message)
    if result[1][:success]

      new_chat = Chat.new(organization_id: organization.id, message_id: 0, message: message, to: params[:cell_phone], from: phone.real, contact_id: contact_id, rate: message_service.sms_rate)
      if !new_chat.save
        flash[:warn] = "Failed to save a record of your message, however message was sent."
      end
    else
      flash[:alert] = "Failed to send your response. Please try again."
    end
    if params[:chat_id]
      redirect_to chat_feed_path(chat_id: params[:chat_id])
    else
      redirect_to chat_feed_path(contact_id: params[:contact_id])
    end
  end

  def get_contacts
    current_organization = current_user.organization
    search_query = params[:search]
    count = 0
    if search_query
      count = current_organization.contacts.where("active = true AND (cell_phone ILIKE ? OR first_name ILIKE ? OR last_name ILIKE ?)", "%#{search_query}%", "%#{search_query}%", "%#{search_query}%").count
      @contacts = current_organization.contacts.where("active = true AND (cell_phone ILIKE ? OR first_name ILIKE ? OR last_name ILIKE ?)", "%#{search_query}%", "%#{search_query}%", "%#{search_query}%").order('cell_phone').limit(10).offset((params[:page].to_i-1)*5)
    else
      count = current_organization.contacts.where(active: true).order('cell_phone').count
      @contacts = current_organization.contacts.where(active: true).order('cell_phone').limit(10).offset((params[:page].to_i-1)*5)
    end
    ## AJAX RESPONSE ##
    if request.xhr?
      respond_to do |format|
        format.json {
          render json: {contacts: @contacts, count_filtered: count, page: params[:page].to_i}
        }
      end
    end
  end

  def remove_chat_addon
    long_code = @organization.phone_numbers.where(long_code: true).first

    twmaster = TwilioMasterService.new()
    results = twmaster.release_number(long_code.service_id)
    if !results["success"]
      message = "Failed to remove the One To One Add On. Please contact customer support. #{results["response"]}"
      return {"success": false, "response": message}
    end

    # Remove the Phone Number
    if !long_code.destroy
      Honeybadger.notify("Failed to destroy long code: #{long_code.id}. | #{long_code.errors.full_messages}", class_name: "Chat Controller -> Remove Chat Add On", error_message: long_code.errors.full_messages)
      return {"success": true}
    end

    return {"success": true}

  end


end
