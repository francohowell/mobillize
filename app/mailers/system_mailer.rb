class SystemMailer < ApplicationMailer
    include SendGrid
    helper :application # gives access to all helpers defined within `application_helper`.
    default from: "noreply@mobilizecomms.com"

    def failed_plan_downgrade_email(user, new_plan, failure_type)
        user = user
        
        mail = SendGrid::Mail.new        
        mail.template_id = 'd-116d829bd1ac41f5b41e0273e4fa08ad '
        mail.from = Email.new(email: 'success@mobilizecomms.com')
        subject = 'Mobilize Comms - Plan Downgrade Failed'
        personalization = Personalization.new
        personalization.add_to(Email.new(email: user.email))
        personalization.add_dynamic_template_data({
            "message" =>  "We are sorry to inform you that your plan downgrade did not succeed. Please contact customer support at: support@mobilizecomms.com",
            "subject" => subject
        })
        mail.add_personalization(personalization)
        response = sendgrid_client.mail._('send').post(request_body: mail.to_json)
  
        if response.status_code != 200
           Honeybadger.notify("Failed To Send Plan Downgrade Failure Email #{user.email}", class_name: "SystemMailer -> Failed Plan Downgrade", error_message: response.body, parameters: response.headers)
        end

    end

    def successful_plan_downgrade_email(user, new_plan)
        user = user
        new_plan = new_plan
        
        mail = SendGrid::Mail.new        
        mail.template_id = 'd-116d829bd1ac41f5b41e0273e4fa08ad '
        mail.from = Email.new(email: 'success@mobilizecomms.com')
        subject = 'Mobilize Comms - Plan Downgrade'
        personalization = Personalization.new
        personalization.add_to(Email.new(email: user.email))
        personalization.add_dynamic_template_data({
            "message" =>  "Your plan has been downgraded to the plan #{new_plan.name}. If you would like to upgrade or change your plan please visit the plans tab in your dashboard.",
            "subject" => subject
        })
        mail.add_personalization(personalization)
        response = sendgrid_client.mail._('send').post(request_body: mail.to_json)
  
        if response.status_code != 200
           Honeybadger.notify("Failed To Send Plan Downgrade Email #{user.email}", class_name: "SystemMailer -> Plan Downgrade", error_message: response.body, parameters: response.headers)
        end

    end

    def upload_confirmation(contacts_upload, user_id)
        user = User.find_by_id(user_id)
        contacts_uploaded = contacts_upload[0]
        contacts_updated = contacts_upload[1]
        contacts_failed = contacts_upload[2]

        mail = SendGrid::Mail.new        
        mail.template_id = 'd-116d829bd1ac41f5b41e0273e4fa08ad '
        mail.from = Email.new(email: 'success@mobilizecomms.com')
        subject = 'Mobilize Comms - Contact Upload'
        personalization = Personalization.new
        personalization.add_to(Email.new(email: user.email))
        personalization.add_dynamic_template_data({
            "message" =>  "Your contact upload has been completed. We were able to add #{contacts_uploaded} contacts and update #{contacts_updated} contacts. Your upload had #{contacts_failed} contact upload failures.",
            "subject" => subject

        })
        mail.add_personalization(personalization)
        response = sendgrid_client.mail._('send').post(request_body: mail.to_json)
  
        if response.status_code != 200
           Honeybadger.notify("Failed To Send Contact Upload Email #{user.email}", class_name: "SystemMailer -> Upload Confirmation", error_message: response.body, parameters: response.headers)
        end

    end

    ## Survey Response Export Error 
    def survey_response_export_error_email(email, error_message)
        mail = SendGrid::Mail.new        
        mail.template_id = 'd-42d85b32ca904b0697a6f08a34e658b6 '
        mail.from = Email.new(email: 'success@mobilizecomms.com')
        subject = 'Mobilize Comms - Survey Export Error'
        mail.subject = subject
        personalization = Personalization.new
        personalization.add_to(Email.new(email: email))
        personalization.add_dynamic_template_data({
            "errorMessage" =>  error_message
        })
        mail.add_personalization(personalization)
        response = @sendgrid_client.mail._('send').post(request_body: mail.to_json)
  
        if response.status_code != 200
           Honeybadger.notify("Failed To Send Password Instructions To User: #{record.id} | #{record.email} | #{response.body}", class_name: "SendGridDeviseMailer -> reset_password", error_message: response.body, parameters: response.headers)
        end
    end

    ## Survey Response Export Success 
    def survey_response_export_success_email(email, message, link) 
        puts "SURVEY RESPONSE EXPORT SUCCESS EMAIL -----||----"
        mail = SendGrid::Mail.new        
        mail.template_id = 'd-61b02c6bc44f46af9f4d3782efcded20'
        mail.from = Email.new(email: 'success@mobilizecomms.com')
        subject = 'Mobilize Comms - Survey Export Success'
        mail.subject = subject
        personalization = Personalization.new
        personalization.add_to(Email.new(email: email))
        personalization.add_dynamic_template_data({
            "message" =>  message,
            "link" => link, 
        })
        mail.add_personalization(personalization)

        response = sendgrid_client.mail._('send').post(request_body: mail.to_json)
  
        if response.status_code.to_i < 200 && response.status_code.to_i > 300
           Honeybadger.notify("Failed To Send Survey Response Export File Email User: #{email}", class_name: "SystemMailer -> Survey Response Export Success Email", error_message: response.body, parameters: response.headers)
        end


    end 

    private 

    def sendgrid_client 
        return  SendGrid::API.new(api_key: Rails.application.credentials.send_grid ).client
    end

    
end
