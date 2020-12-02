# app/jobs/hello_world_job.rb
# frozen_string_literal: true
class SurveyExportJob
    include Sidekiq::Worker
    include SendGrid

    sidekiq_options queue: 'default'
    
    def perform(survey_id, user_id, start_date, end_date)

        puts "SRUVEY -=-_> #{start_date} #{end_date}"
        
        user = User.find_by_id(user_id)
        organization = user.organization
        survey = organization.surveys.find_by_id(survey_id)

        if !survey

            mail = create_email('d-42d85b32ca904b0697a6f08a34e658b6', user.email, {
                "errorMessage" =>   "The survey you requested data for is no longer available or this account no longer has access to the survey. Please make sure you can access the survey through the dashboard or contact customer support at: support@mobilizus.com",
                "subject" => 'Mobilize Comms - Survey Export Error'
            })
    
            response = sendgrid_client.mail._('send').post(request_body: mail.to_json)
      
            if response.status_code.to_i < 200 && response.status_code.to_i > 300
               Honeybadger.notify("Failed To Send Survey Response Export File Email User: #{user.email}", class_name: "SurveyExportJob", error_message: response.body, parameters: response.headers)
            end

            return
        end

        # Generate CSV File
        client = Aws::S3::Client.new(
            region: 'us-west-2',
            credentials: Aws::Credentials.new(Rails.application.credentials[:aws_access_key_id], Rails.application.credentials[:aws_secret_access_key])
        )

        obj = Aws::S3::Object.new('musapp', "exports/surveys/#{survey.id}-#{survey.name}-Survey-Reponses-#{DateTime.now.in_time_zone(organization.timezone)}.csv", client: client)

        obj.upload_stream(acl: 'public-read') do |write_stream|
            header = ["Response Id", "Contact Id", "Contact Number", "Created At"]
            ordered_questions = survey.survey_questions.order(:order)
            ordered_questions.each do |q|
              #question = Nokogiri::HTML(q.question).text
              question = ActionView::Base.full_sanitizer.sanitize(q.question)
              puts question
              header.push(question)
              if q.is_location?
                header.push("Zip Code")
              end
            end

            puts header

            write_stream << CSV.generate_line(header)

            survey.survey_responses.where("created_at >= ? AND created_at <= ?", start_date.nil? ? survey.created_at : start_date, end_date.nil? ? Time.now : end_date).find_each do |resp|

                puts "RESP: #{resp.id}"
    
                row = [resp.id, resp.contact_id, resp.contact_number, resp.created_at.in_time_zone(survey.organization.timezone)]

                puts "PRE ROW: #{row}"
                
                for question in ordered_questions
                    puts "QUESTION: #{question.id}"
                    if !ActiveSupport::TimeZone.us_zones.include?(organization.timezone)
                        question.min_range = Date.strptime(question.min_range, '%m/%d/%Y').strftime('%d-%m-%Y') rescue ''
                        question.max_range = Date.strptime(question.max_range, '%m/%d/%Y').strftime('%d-%m-%Y') rescue ''
                    end
                    answer = survey.survey_answers.find_by(survey_question_id: question.id, survey_response_id: resp.id)
                    if answer
                        if question.is_mc?
                            puts "MC----"
                            if question.survey_multiple_choices.find_by_id(answer.answer)
                                row.push(question.survey_multiple_choices.find_by_id(answer.answer).choice_item)
                            else
                                row.push(answer.answer)
                            end
                        elsif question.is_location?
                            row.push(answer.answer)
                            row.push(get_zip(answer.answer))
                        else
                            row.push(answer.answer)
                        end   
                    else
                        row.push("")
                    end
                end

                write_stream << CSV.generate_line(row)
        
            end

        end

        puts "------> OBJECT: #{obj}"

        # Send User Email With Download Link
        # SystemMailer.survey_response_export_success_email(user.email, "Your survey responses are ready for download!", obj.public_url)

        mail = create_email('d-61b02c6bc44f46af9f4d3782efcded20', user.email, {
            "message" =>   "Your survey responses are ready for download! This link will only be available for 24 hours.",
            "link" => obj.public_url,
            "subject" => 'Mobilize Comms - Survey Export Success'
        })

        response = sendgrid_client.mail._('send').post(request_body: mail.to_json)
  
        if response.status_code.to_i < 200 && response.status_code.to_i > 300
           Honeybadger.notify("Failed To Send Survey Response Export File Email User: #{user.email}", class_name: "SystemMailer -> Survey Response Export Success Email", error_message: response.body, parameters: response.headers)
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

    def get_zip(full_address)
      regex = /\b\d{5}(-\d{4})?\b/
      if full_address.match(regex)
        return full_address.match(regex)[0]
      else
        "" 
      end
    end
end
