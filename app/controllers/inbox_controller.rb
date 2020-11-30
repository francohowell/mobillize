class InboxController < ApplicationController
  include Pagy::Backend
  before_action :authenticate_user!

  def overview
    start_date = params[:start_date]
    end_date = params[:end_date]

    if start_date && end_date && !start_date.blank? && !end_date.blank?
      @pagy, @responses = pagy(Response.where("keyword IN (?) AND created_at BETWEEN ? AND ?", current_user.organization.keyword_names, Date.strptime(start_date, '%m/%d/%Y'), Date.strptime(end_date, '%m/%d/%Y') ).where.not(opt_out: true).order("created_at DESC"), limit: 25)
    else
      @pagy, @responses = pagy(Response.where(keyword: current_user.organization.keyword_names ).where.not(opt_out: true).order("created_at DESC"), limit: 25)
    end
  end

  def overview_mobile
    start_date = params[:start_date]
    end_date = params[:end_date]
    if start_date && end_date
      @pagy, @responses = pagy(Response.where("keyword IN (?) AND created_at BETWEEN ? AND ?", current_user.organization.keyword_names, Date.strptime(start_date, '%m/%d/%Y'), Date.strptime(end_date, '%m/%d/%Y') ).where.not(opt_out: true).order("created_at DESC"), limit: 25)
    else
      @pagy, @responses = pagy(Response.where(keyword: current_user.organization.keyword_names ).where.not(opt_out: true).order("created_at DESC"), limit: 25)
    end
  end

  def export_responses
    start_date = params[:start_date]
    end_date = params[:end_date]
    if start_date && end_date
      @responses = Response.where("keyword IN (?) AND created_at BETWEEN ? AND ?", current_user.organization.keyword_names, Date.strptime(start_date, '%m/%d/%Y'), Date.strptime(end_date, '%m/%d/%Y') ).where.not(opt_out: true).order("created_at DESC")
    else
      @responses = Response.where(keyword: current_user.organization.keyword_names ).where.not(opt_out: true).order("created_at DESC")
    end

    respond_to do |format|
      format.csv { send_data @responses.to_csv, filename: "Mobilize-US-#{current_user.organization.name}-Responses-#{start_date.nil? ? "Most-Recent-#{Date.today}":"#{start_date}-#{end_date}"}.csv" }
    end
  end

  def feed
    @contact = Contact.find_by_id(params[:contact_id])
    @responses = Response.where(contact_id: @contact.id).where.not(opt_out: true).order("created_at DESC")
    @organization = current_user.organization
    @relationship = OrganizationContactRelationship.find_by(organization_id: @organization.id, contact_id: @contact.id)
    if @relationship
      @message_history = DirectMessage.where(organization_contact_relationship_id: @relationship.id).order("created_at DESC")
    else
      @message_history = nil
    end
    @long_code = @organization.phone_numbers.where(long_code: true).first
  end

  def opt_outs
    @pagy_op, @opt_outs = pagy(Response.where(keyword: current_user.organization.keyword_names, opt_out: true ).order("created_at DESC"), limit: 25)
  end

  def twilio_send
    organization = current_user.organization
    contact = Contact.find_by_id(params[:contact_id])
    message = params[:message]
    twilio_format_contact = "#{"+"}#{contact.cell_phone}"
    phone = organization.phone_numbers.where(long_code: true).first
    twilio_format_from = "#{"+"}#{phone.real}"
    org = OrganizationContactRelationship.find_by(organization_id: organization.id, contact_id: contact.id)

    twilio_manager = TwilioMasterService.new()
    dm = DirectMessage.where(organization_contact_relationship_id: org.id)
    if dm.empty?
      twilio_manager.send_direct_message( twilio_format_from, twilio_format_contact, "Welcome. This is a private message line between you and #{organization.name}. This is automated message and all data rates apply.")
    end
    result = twilio_manager.send_direct_message( twilio_format_from, twilio_format_contact, message)
    if result[1][:success]
      dm = DirectMessage.new(organization_contact_relationship_id: org.id, message_id: 0, media: false, message: message, to: contact.cell_phone, from: phone.real)
      if !dm.save
        flash[:warn] = "Failed to save a record of your message, however message was sent."
      end
    else
      flash[:alert] = "Failed to send your response. Please try again"
    end
    redirect_to inbox_overview_path
  end

end
