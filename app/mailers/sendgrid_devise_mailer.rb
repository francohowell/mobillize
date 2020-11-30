class SendgridDeviseMailer < Devise::Mailer
   include SendGrid
   helper :application # gives access to all helpers defined within `application_helper`.
   include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`

   def sendgrid_client
      return sendgrid_client = SendGrid::API.new(api_key: Rails.application.credentials.send_grid ).client
   end

   def reset_password_instructions(record, token, opts={})

      mail = SendGrid::Mail.new        
      mail.template_id = 'd-259f566aa2294ac5ba0a98d3197d3c62'
      mail.from = Email.new(email: 'success@mobilizecomms.com')
      subject = 'Mobilize Comms - Forgot Password Instructions'
      personalization = Personalization.new
      personalization.add_to(Email.new(email: record.email))
      personalization.add_dynamic_template_data({
          "resetLink" =>  edit_password_url(record, reset_password_token: token),
          "subject" => subject
      })
      mail.add_personalization(personalization)
      response = sendgrid_client.mail._('send').post(request_body: mail.to_json)

      if response.status_code.to_i < 200 && response.status_code.to_i > 300
         Honeybadger.notify("Failed To Send Password Instructions To User: #{record.id} | #{record.email} | #{response.body}", class_name: "SendGridDeviseMailer -> reset_password", error_message: response.body, parameters: response.headers)
      end

   end

   def confirmation_instructions(record, token, opts={})
      mail = SendGrid::Mail.new        
      mail.template_id = 'd-c8e7595ec7aa461fa560a6fe58466942'
      mail.from = Email.new(email: 'success@mobilizecomms.com')
      subject = 'Mobilize Comms - Confirmation Instructions'
      personalization = Personalization.new
      personalization.add_to(Email.new(email: record.email))
      personalization.add_dynamic_template_data({
          "confirmationLink" =>  confirmation_url(record, :confirmation_token => record.confirmation_token),
          "subject" => subject
      })
      mail.add_personalization(personalization)
      response = sendgrid_client.mail._('send').post(request_body: mail.to_json)

      if response.status_code.to_i < 200 && response.status_code.to_i > 300
         Honeybadger.notify("Failed To Send Confirmation Instructions To User: #{record.id} | #{record.email} | #{response.body}", class_name: "SendGridDeviseMailer -> Confirmation Instructions", error_message: response.body, parameters: response.headers)
      end
   end


end