require 'smstools'

class BlastController < ApplicationController
  include Pagy::Backend
  include PaymentProcessor

  before_action :authenticate_user!

  def new
    @current_organization = current_user.organization
    @plan = @current_organization.plan
    @usage = @current_organization.current_credit_usage

    @org_groups = @current_organization.groups_with_contacts
    @org_contacts = @current_organization.contacts
    @org_keywords = @current_organization.keywords
    @max_message_length = 1000
    @current_date = Time.now.in_time_zone(@current_organization.timezone)
    @repeation_options = ["Daily", "Weekly", "Monthly"]
    @blast = Blast.new
    @blast_attachment = @blast.blast_attachments.build
    @count = current_user.organization.contacts.where(active: true).count
    if params[:search]
      search_value =  params[:search]
      @pagy, @your_contacts = pagy(current_user.organization.contacts.where("active = true AND (cell_phone ILIKE ? OR first_name ILIKE ? OR last_name ILIKE ?)", "%#{search_value}%", "%#{search_value}%", "%#{search_value}%"), limit: 10)
    else
      @pagy, @your_contacts = pagy(current_user.organization.contacts.where(active: true), limit: 10)
    end

    logger.info("FINAL RETURN VALUE: #{@msg_count}")

  end

  def new_review
    logger.info("PARAMS: #{params}")

    @current_organization = current_user.organization
    @plan = @current_organization.plan
    @usage = @current_organization.current_credit_usage
    @sms_result = 1
    @msg_count = 0
    @contact_count = 0
    @keyword = params[:keyword]
    mms = params[:mms]

    logger.info("MESSAGE: #{params[:message]}")

    blast_message = params[:message]
    blast_message = character_replacement(blast_message)
    if mms == "false"
      if blast_message
        if @keyword
          @sms_result = sms_check("#{@keyword} #{blast_message}")
        else
          @sms_result = sms_check(blast_message)
        end
      end
    else
      @sms_result = 3 # Base MMS Rate
    end

    if params[:contacts_all_js] == "false"
      group_array = nil
      if params[:groups_js] && params[:groups_js] != ""# Get the groups count
        group_array = params[:groups_js]
        puts "GROUP ARRAY: #{group_array}"
      end
      contact_array = nil
      if params[:contacts_js] && params[:contacts_js] != "" # Get the groups count
        contact_array = params[:contacts_js]
        if contact_array.first == "null"
          contact_array = []
        end
      end

      logger.info("MESSAGE CALCULATION: #{group_array}, #{contact_array}")

      @msg_count = helpers.calculate_messages_to_be_used(group_array, contact_array)
    elsif   params[:contacts_all_js] == "true"
      @msg_count = current_user.organization.contacts.where(active: true).count
    else
      @msg_count = 0
    end
    @contact_count = @msg_count

    logger.info("MESSAGE COUNT: #{@msg_count}")

    @msg_count = @msg_count * @sms_result

    if @msg_count < 0.5 && @msg_count != 0
      @msg_count = 0.5
    end

     ## AJAX RESPONSE ##
     if request.xhr?
      respond_to do |format|
        format.json {
          render json: {msg_count: @msg_count, sms_check: @sms_result, contact_count: @contact_count}
        }
      end
    end
  end

  def get_contacts
    puts "----------> #{DateTime.now}"
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

  def edit
    @current_organization = current_user.organization
    @current_blast = Blast.find_by_id(params[:id])
    @org_keywords = @current_organization.keywords
    @current_date = Time.now.in_time_zone(@current_organization.timezone)
    @max_message_length = 1000
    @current_message_length = "#{@current_blast.keyword_name} #{@current_blast.message}".length
  end

  def update
    edit_blast = Blast.find_by_id(params[:id])
    keyword = Keyword.find_by_name(params[:keyword])
    edit_blast.message = params[:message]
    edit_blast.keyword_id = keyword.id
    edit_blast.keyword_name = keyword.name
    if !edit_blast.save
      flash[:alert] = edit_blast.errors.full_messages
      redirect_to blast_edit_path(id: edit_blast.id)
      return
    else
      flash[:success] = "Blast #{edit_blast.id} has been updated!"
      redirect_to blast_overview_path
      return
    end
  end

  def delete
    # Delete the blast
    b = Blast.find_by_id(params[:id])
    b.destroy

    # Delete the Contact Relationships
    BlastContactRelationship.where(blast_id: params[:id]).destroy_all

    flash[:success] = "Blast has been deleted."
  end

  def create
    logger.info("Executing Blast Create Method")

    group_ids = params[:groups]
    contact_ids = params[:contact_ids]
    contact_all = params[:contacts_all] ? params[:contacts_all] : false
    message = params[:message]

    #--> Can user send blasts <--#
    #RS do we need to check phone number? looks like user cannot be signed up without one so not necessary
    if current_user.can_send_blasts
      redirect_to blast_new_path
      return
    end

    keyword = params[:keyword]
    #--> RS - think we can remove this code block since users can send without a keyowrd <--#
    #   if keyword.nil?
    #    flash[:alert] = "You must select a keyword to send a blast."
    #    redirect_to blast_new_path
    #     return
    #    end
    #--> Keyword <--#
    keyword_object = Keyword.find_by_name(keyword)

    if message.nil?
      flash[:alert] = "You must provide a message to send a blast."
      redirect_to blast_new_path
      return
    end

    #--> Message Type <--#
    message = character_replacement(message)
    sms_rate = 1
    if !params[:blast]
      sms_rate = sms_check("#{keyword_object.name} #{message}")
    end

    #--> Check To See If The Blast Will Exceed The Account Limit <--#
    count = helpers.calculate_messages_to_be_used(group_ids, contact_ids)
    if contact_all
      count = helpers.calculate_messages_to_be_used(group_ids, [])
      count += current_user.organization.contacts.where(active: true).count
    else
      count = helpers.calculate_messages_to_be_used(group_ids, contact_ids)
    end

    cost_count = count
    cost_count = cost_count * sms_rate

    usage = current_user.organization.current_credit_usage
    predicted_use = cost_count + usage
    if predicted_use > current_user.organization.annual_credits
      flash[:alert] = "You do not have enough credits to send this blast. Please upgrade your plan."
      redirect_to blast_new_path
      return
    end


    #--> Quick Presence Validations <--#
    if group_ids.nil? && contact_ids.nil? && !contact_all
      flash[:alert] = "You must select at least one contact or one group with contacts to send a blast."
      redirect_to blast_new_path
      return
    end



    immediate_send = params[:immediate_send]
    send_date = params[:date]
    send_time = params[:time]
    if immediate_send.nil?
      if send_date.nil? && send_time.nil?
        flash[:alert] = "You must provide a date and time or select send now to send a blast."
        redirect_to blast_new_path
        return
      end
    end

    repeat = params[:repeat]
    repeat_end_date = params[:end_repeat_date]
    if repeat
      if repeat_end_date.nil?
        flash[:alert] = "You must provide an end date to setup and start a repeating blast."
        redirect_to blast_new_path
        return
      end
    end

# RS: since this is coming from the web site and the user can select who exactly to send to, we can leave as is.
    contact_array = []
    if !contact_all
      #--> Group Contacts <--#
      if group_ids
        for g in group_ids
          contact_array += Group.find_by_id(g).get_all_contacts
          logger.info("Contact Array for Group #{g} - #{contact_array}")
        end
      end

      #--> Contact Combine <--#
      if contact_ids
        for c_id in contact_ids
          contact_array.push(Contact.find_by_id(c_id))
        end
      end

      contact_array.uniq!
    else
      contact_array = current_user.organization.contacts.where(active: true)
    end

    logger.info("Contact Array Count: #{contact_array.count}")
    if contact_array.count == 0
      flash[:alert] = "You must at least one contact or a group with at least one contact for a new blast to be created."
      redirect_to blast_new_path
      return
    end



    scheduled_time = nil
    #--> Sending Date & Time <--#
    if !immediate_send
      formated_date = Date.strptime(send_date, '%m/%d/%Y')
      formated_time = send_time.to_time
      current_time = Time.now.utc
      scheduled_time = Time.find_zone(current_user.organization.timezone).local(formated_date.year, formated_date.month, formated_date.day, formated_time.hour, formated_time.min).utc
      logger.info("Scheduled TIME: #{scheduled_time} | CURRENT TIME: #{current_time}")
      if scheduled_time <= current_time
        flash[:alert] = "You must choose a scheduled date and time that is after today's current date and time."
        redirect_to blast_new_path
        return
      end
    else
      scheduled_time = Time.now
    end

    formated_end_date = nil
    #--> Recurring Message <--#
    if !repeat.blank?
      formated_end_date = Date.strptime(repeat_end_date, '%m/%d/%Y')
      if !scheduled_time
        if formated_end_date <= Date.today
          flash[:alert] = "You must choose a recurring end date is after today."
          redirect_to blast_new_path
          return
        end
        six_month_stop_date = Time.now + 6.months
        if formated_end_date > six_month_stop_date
          flash[:alert] = "You cannot schedule more than 6 months in advance."
          redirect_to blast_new_path
          return
        end
      else
        # Ensure that the recurring end date is not before the scheduled start date
        logger.info("SCHEDULED DATE: #{scheduled_time.to_date} | END DATE: #{formated_end_date}")
        if scheduled_time.to_date >= formated_end_date
          flash[:alert] = "Your recurring end date must be after your scheduled date."
          redirect_to blast_new_path
          return
        end
        six_month_stop_date = scheduled_time.to_date + 6.months
        if formated_end_date > six_month_stop_date
          flash[:alert] = "You cannot schedule more than 6 months in advance."
          redirect_to blast_new_path
          return
        end
      end
    end

    # Process Blast Record
    sms = true
    if params[:blast]
      if params[:blast][:media_attachments]
        sms = false
      end
    end
    created_blast = Blast.new(user_id: current_user.id, organization: current_user.organization, active: true, keyword_id: keyword_object.id, keyword_name: keyword_object.name, message: message, sms: sms, repeat: repeat, repeat_end_date: formated_end_date, send_date_time: scheduled_time, contact_count: count, cost: cost_count, rate: sms_rate)
    if created_blast.save

      #--> Images <--# (ON SAVE)
      if params[:blast]
        if params[:blast][:media_attachments]
          media = params[:blast][:media_attachments]
          puts "---> #{media}"
          blast_attachment = BlastAttachment.new(attachment: media, blast_id: created_blast.id)
          if !blast_attachment.save
            flash[:alert] = blast_attachment.errors.full_messages
            created_blast.destroy
            redirect_to blast_new_path
            return
          end
        end
      end

      #--> Contacts <--#
      for c in contact_array
        contact_relationship = BlastContactRelationship.new(blast: created_blast, status: "Sent", contact_id: c.id)
        if !contact_relationship.save
          flash[:alert] = contact_relationship.errors.full_messages
          created_blast.destroy
          redirect_to blast_new_path
          return
        end
      end

      #--> Groups <--#
      if group_ids
        for g in group_ids
          logger.info("Processing Groups #{g}")
          blast_group_relationship = BlastGroupRelationship.new(blast: created_blast, group_id: g)
          if !blast_group_relationship.save
            logger.info("Failed Processing Groups #{g}")
            flash[:alert] = blast_group_relationship.errors.full_messages
            created_blast.destroy
            redirect_to blast_new_path
            return
          end
        end
      end

      #--> mGage Process <--#
      if immediate_send
        if repeat.blank? # Process Scheduled Only
          helpers.set_blast_job(current_user.organization.id, created_blast, nil)
        else # Process Scheduled & Repeating Blast

          dates = created_blast.repeating_send_dates

          for d in dates
            helpers.set_blast_job(current_user.organization.id, created_blast, d)
          end

        end
      else
        if repeat.blank? # Process Scheduled Only
          logger.info("----> TIME SUBMITTED: #{Time.parse(scheduled_time.to_s)}")
          helpers.set_blast_job(current_user.organization.id, created_blast, scheduled_time)

        else # Process Scheduled & Repeating Blast

          dates = created_blast.repeating_send_dates

          for d in dates
            helpers.set_blast_job(current_user.organization.id, created_blast, d)
          end

        end
      end

      flash[:success] = "Your blast has been created!"
      redirect_to blast_overview_path
      return

    else
      flash[:alert] = created_blast.errors.full_messages
      redirect_to blast_new_path
      return
    end
  end

  def overview
    user_blasts = current_user.organization.blasts.order("created_at DESC")
    @pagy_b, @blasts = pagy(user_blasts)
  end

  def show
    blast_id = params[:blast_id]
    @blast = Blast.find_by_id(blast_id)
    @user = User.find_by_id(@blast.user_id)
    @blast_groups = @blast.groups
    @pagy_c, @blast_contacts = pagy(@blast.blast_contact_relationships, limit: 25)
  end

  def purchase
    logger.info("Executing Blast Purchase Method")

    group_ids = params[:groups]
    contact_ids = params[:contacts]
    contact_all = params[:contacts_all] ? params[:contacts_all] : false

    #--> Quick Presence Validations <--#
    if group_ids.nil? && contact_ids.nil? && !contact_all
      flash[:alert] = "You must select at least one contact or one group with contacts to send a blast."
      redirect_to blast_new_path
      return
    end

    keyword = params[:keyword]
    if keyword.nil?
      flash[:alert] = "You must select a keyword to send a blast."
      redirect_to blast_new_path
      return
    end

    message = params[:message]
    if message.nil?
      flash[:alert] = "You must provide a message to send a blast."
      redirect_to blast_new_path
      return
    end

    #--> Check To See If The Blast Will Exceed The Account Limit <--#
    count = helpers.calculate_messages_to_be_used(group_ids, contact_ids)
    if contact_all
      count = helpers.calculate_messages_to_be_used(group_ids, [])
      count += current_user.organization.contacts.where(active: true).count
    else
      count = helpers.calculate_messages_to_be_used(group_ids, contact_ids)
    end



    contact_array = []
    if !contact_all
      #--> Group Contacts <--#
      if group_ids
        for g in group_ids
          contact_array += Group.find_by_id(g).get_all_contacts
          logger.info("Contact Array for Group #{g} - #{contact_array}")
        end
      end

      #--> Contact Combine <--#
      if contact_ids
        for c_id in contact_ids
          contact_array.push(Contact.find_by_id(c_id))
        end
      end

      contact_array.uniq!
    else
      contact_array = current_user.organization.contacts.where(active: true)
    end

    logger.info("Contact Array Count: #{contact_array.count}")
    if contact_array.count == 0
      flash[:alert] = "You must at least one contact or a group with at least one contact for a new blast to be created."
      redirect_to blast_new_path
      return
    end

    #--> Keyword <--#
    keyword_object = Keyword.find_by_name(keyword)

    #--> Message <--#
    message = character_replacement(message)
    sms_rate = 1
    if !params[:blast]
      sms_rate = sms_check("#{keyword_object.name} #{message}")
    end

    scheduled_time = Time.now

    # Create Charge
    charge_amount = count * 0.05
    charge_amount = charge_amount * sms_rate

    if charge_amount < 0.5
      charge_amount = 0.50
    end

    blast_charge = immediate_charge(charge_amount, "#{keyword_object.name} - #{count} - #{message}", current_user.organization)
    if !blast_charge["success"] # Plan upgrade failed in Stripe
      flash[:failure] = blast_charge["error_message"]
      redirect_to blast_new_path()
      return
    end
    # Process Blast Record
    created_blast = Blast.new(user_id: current_user.id, organization: current_user.organization, active: true, keyword_id: keyword_object.id, keyword_name: keyword_object.name, message: message, sms: params[:media_attachments] ? false : true, send_date_time: scheduled_time, stripe_id: blast_charge["data"][:id], contact_count: count, cost: charge_amount, rate: sms_rate)
    if created_blast.save
      #--> Images <--# (ON SAVE)
      if params[:media_attachments]
        params[:media_attachments]['attachment'].each do |a|
          blast_attachment = created_blast.blast_attachments.new(:attachment => a, :blast => created_blast)
          if !blast_attachment.save
            flash[:alert] = blast_attachment.errors.full_messages
            created_blast.destroy
            redirect_to blast_new_path
            return
          end
        end
      end

      #--> Contacts <--#
      for c in contact_array
        contact_relationship = BlastContactRelationship.new(blast: created_blast, status: "Sent", contact_id: c.id)
        if !contact_relationship.save
          flash[:alert] = contact_relationship.errors.full_messages
          created_blast.destroy
          redirect_to blast_new_path
          return
        end
      end

      #--> Groups <--#
      if group_ids
        for g in group_ids
          logger.info("Processing Groups #{g}")
          blast_group_relationship = BlastGroupRelationship.new(blast: created_blast, group_id: g)
          if !blast_group_relationship.save
            logger.info("Failed Processing Groups #{g}")
            flash[:alert] = blast_group_relationship.errors.full_messages
            created_blast.destroy
            redirect_to blast_new_path
            return
          end
        end
      end

      #--> mGage Process <--#
      helpers.set_blast_job(current_user.organization.id, created_blast, nil)


      flash[:success] = "Your blast has been purchased & sent!"
      redirect_to blast_overview_path
      return

    else
      flash[:alert] = created_blast.errors.full_messages
      redirect_to blast_new_path
      return
    end
  end

  private

    def character_replacement(message)
      message.gsub!(/\u2019/, "\u0027") # Replace a right single quote with apostrophe
      message.gsub!(/\u2018/, "\u0027") # Replace a left single quote with apostrophe
      return message
    end

    def sms_check(message)
      # credit_rate
      logger.info("SMS ENCODING: #{message}")
      sms_encoding = SmsTools::EncodingDetection.new message
      logger.info("Encoding Detection: #{sms_encoding.encoding}")

      if SmsTools::GsmEncoding.valid? message
        if message.length <= 160
          return 1
        else
          if sms_encoding.concatenated?
            return sms_encoding.concatenated_parts
          else
            return 1
          end
        end
      else
        if message.length <= 70
          return 1
        else
          if sms_encoding.concatenated?
            return sms_encoding.concatenated_parts
          else
            return 1
          end
        end
      end
    end

end
