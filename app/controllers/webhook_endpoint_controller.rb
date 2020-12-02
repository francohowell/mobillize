class WebhookEndpointController < ApplicationController
  include SendGrid

  skip_before_action :verify_authenticity_token
  skip_before_action :notification_check
  skip_before_action :active_billing_status
  protect_from_forgery with: :null_session

  layout 'empty'

  def stripe_endpoint
    logger.info("Stripe Event Triggered")

    # source.failed
    # source.canceled
    #-- invoice.payment_failed
    #-- charge.failed

    payload = request.body.read
    event = nil
  
    begin
      event = Stripe::Event.construct_from(
        JSON.parse(payload, symbolize_names: true)
      )
    rescue JSON::ParserError => e
      # Invalid payload
      Honeybadger.notify("Failed to obtain stripe webhook evetns. | #{e}", class_name: "Webhook Endpoint -> Stripe Endpoint", error_message: e, parameters: params)
      render nothing: true, status: 400
      return
    end
  
    # Handle the event (Currently failed payment only)
    case event.type
    when 'charge.failed', 'invoice.payment_failed', 'source.failed'
      charge_obj = event.data.object
      charge_failed(charge_obj)
    else
      # Unexpected event type
      Honeybadger.notify("Unexpected Stripe Webhook Event | #{payload}", class_name: "Webhook Endpoint -> Stripe Endpoint", parameters: params)
      render nothing: true, status: 400
      return
    end
  
    render nothing: true, status: 200
    return
  end

  private 

  def charge_failed(charge_object)

    customer = charge_object.customer 
    
    # TESTING PURPOSES ONLY -> Default Staging Test Account
    customer = customer == "cus_00000000000000" ? "cus_HoLRCqKOeRbvKE" : customer
    stripe_account = StripeAccount.find_by_stripe_id(customer)

    if stripe_account
      stripe_account.active = false 
      if !stripe_account.save 
        Honeybadger.notify("Could not update stripe account with active false | #{stripe_account.id} | #{stripe_account.errors.full_messages}", class_name: "Webhook Endpoint -> Charge Failed", parameters: params)
      end 

      organization = stripe_account.organization

      process_email("Payment Failed", organization, {
        "message" =>  "We are sorry to inform you that your payment could not be processed. Please update your payment details by #{(Time.now + 1.weeks).in_time_zone(organization.timezone)..strftime('%m/%d/%Y')} or your account will be deactivated. \n\n If you have any issues or need support please contact customer support at: support@mobilizeus.com",
        "paymentSourceLink" => "https://#{Rails.application.routes.default_url_options[:host]}/billing/overview"
      })

    else
      Honeybadger.notify("Could not find a record in the stripe account with the customer id | #{customer}", class_name: "Webhook Endpoint -> Charge Failed", parameters: params)
    end
  end

  ## SendGrid ## 

  def sendgrid_client 
    return  SendGrid::API.new(api_key: Rails.application.credentials.send_grid ).client
  end

  def process_email(subject_detail, organization, template_data_json)
    mail = SendGrid::Mail.new        
    mail.template_id = 'd-d8d56b63674f4439aabae2075ef62b08'
    mail.from = Email.new(email: 'success@mobilizecomms.com')
    subject = 'Mobilize Comms - #{subject_detail}'
    personalization = Personalization.new
    for org_user in organization.users
      personalization.add_to(Email.new(email: org_user.email))
    end
    personalization.add_dynamic_template_data(template_data_json)
    mail.add_personalization(personalization)
    response = sendgrid_client.mail._('send').post(request_body: mail.to_json)

    if response.status_code != 200
        Honeybadger.notify("Failed To Send Plan Downgrade Failure Email for Organization | #{organization.id} - #{organization.name}", class_name: "Webhook Endpoint -> Charge Failed", error_message: response.body, parameters: response.headers)
    end
  end


end
