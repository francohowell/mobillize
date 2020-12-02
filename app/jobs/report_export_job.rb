# app/jobs/hello_world_job.rb
# frozen_string_literal: true
class ReportExportJob
    include Sidekiq::Worker
    include SendGrid

    sidekiq_options queue: 'default'
    
    def perform(report_type, month, year, user_id)
        user = User.find_by_id(user_id)
        organization = user.organization

        case report_type
        when "blast_report"
            create_blast_report(month, year.to_i, user, organization)
        else
            mail = create_email('d-42d85b32ca904b0697a6f08a34e658b6', user.email, {
                "errorMessage" =>   "The report you requested data for is no longer available. Please make sure you can access the report through the dashboard or contact customer support at: support@mobilizus.com",
                "subject" => 'Mobilize Comms - Report Error'
            })
    
            response = sendgrid_client.mail._('send').post(request_body: mail.to_json)
      
            if response.status_code.to_i < 200 && response.status_code.to_i > 300
               Honeybadger.notify("Failed To Send Report Failure Email User: #{user.emial}", class_name: "ReportExportJob", error_message: response.body, parameters: response.headers)
            end

        end

        return
        
    end

    private

    def sendgrid_client 
        return  SendGrid::API.new(api_key: Rails.application.credentials.send_grid ).client
    end

    def create_email(template_id, to_email, template_data)
        mail = SendGrid::Mail.new        
        mail.template_id = template_id
        mail.from = Email.new(email: 'success@mobilizecomms.com')
        personalization = Personalization.new
        personalization.add_to(Email.new(email: to_email))
        personalization.add_dynamic_template_data(template_data)
        mail.add_personalization(personalization)

        return mail
    end

    def create_blast_report(month, year, user, organization)
        
        if month && year
            date = DateTime.new(year, Date::MONTHNAMES.index(month), 1)
            month_start = date.at_beginning_of_month
            month_end = date.at_end_of_month
            month = month
            year = year
        else
            today = DateTime.now
            month_start = today.at_beginning_of_month
            month_end = today.at_end_of_month
            month = Date::MONTHNAMES[today.month]
            year = today.year
        end

        client = Aws::S3::Client.new(
            region: 'us-west-2',
            credentials: Aws::Credentials.new(Rails.application.credentials[:aws_access_key_id], Rails.application.credentials[:aws_secret_access_key])
        )

        obj = Aws::S3::Object.new('musapp', "exports/reports/#{organization.id}-Blast-Report-#{month_start.month}-#{month_start.year}.csv", client: client)

        obj.upload_stream(acl: 'public-read') do |write_stream|
            header = ["Id", "Organization", "Send Date Time", "Keyword", "Message", "Contact Count", "Rate", "Cost", "SMS", "Groups", "Repeat"]

            write_stream << CSV.generate_line(header)

            sent_count = 0
            for b in organization.blasts.where("send_date_time BETWEEN ? AND ?", month_start, month_end).order("send_date_time DESC")
                groups = b.groups.pluck(:name).join(" | ")
                write_stream << CSV.generate_line([b.id, organization.id, b.send_date_time.in_time_zone(organization.timezone), b.keyword_name, b.outgoing_message, b.contact_count, b.rate, b.cost, b.sms ? "True" : "False", groups, b.repeat])
            end
        end

        mail = create_email('d-61b02c6bc44f46af9f4d3782efcded20', user.email, {
            "message" =>   "Your Blast Report is ready for download! This link will only be available for 24 hours.",
            "link" => obj.public_url, 
            "subject" => "Mobilize Comms - Blast Report #{month} #{year}"
        })

        response = sendgrid_client.mail._('send').post(request_body: mail.to_json)
  
        if response.status_code.to_i < 200 && response.status_code.to_i > 300
           Honeybadger.notify("Failed To Send Blast Report Email User: #{user.email} | #{response.body} ", class_name: "ReportExport -> Create Blast Report", error_message: response.body, parameters: response.headers)
        end


      end
     


end
