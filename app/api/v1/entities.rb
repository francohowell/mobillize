
module V1
    module Entities
        class ErrorResponse < Grape::Entity
            expose :status_code, documentation: { type: "Integer", desc: "HTTP Status"}
            expose :response_type, documentation: { type: "String", desc: "Success or Failure"}
            expose :details, documentation: { type: "String", desc: "Message about the success."}
        end
    end
end

module V1
    module Entities
        class Contact < Grape::Entity
            expose :status_code, documentation: { type: "Integer", desc: "HTTP Status"}
            expose :response_type, documentation: { type: "String", desc: "Success or Failure"}
            expose :details, documentation: { type: "String", desc: "Message about the success."}
            expose :data, documentation: { type: "Array", desc: "Data array for the objects returned."} do
                expose :id, documentation: { type: "Integer", desc: "Id of the contact."} 
                expose :first_name, documentation: { type: "String", desc: "First name of the contact."}
                expose :last_name, documentation: { type: "String", desc: "First name of the contact."}
                expose :primary_email, documentation: { type: "String", desc: "Primary email of the contact."}
                expose :secondary_email, documentation: { type: "String", desc: "Secondary email of the contact."}
                expose :cell_phone, documentation: { type: "String", desc: "Cell phone number of the contact."}
                expose :active, documentation: { type: "Boolean", desc: "Active status of the contact (default: true)."}
                expose :company_name, documentation: { type: "String", desc: "Company name of the contact."}
                expose :organization_id, documentation: { type: "Integer", desc: "Id of the organization of the contact."}
                expose :user_id, documentation: { type: "String", desc: "Id of the user that created the contact. (default 0 for non-users)"}
                expose :created_at, documentation: { type: "DateTime", desc: "DateTime of when the contact was created."}
                expose :updated_at, documentation: { type: "DateTime", desc: "DateTime of when the contact was last updated."}
                expose :carrier, documentation: { type: "String", desc: "Carrier name of the contact."}
                expose :country, documentation: { type: "String", desc: "Country name of the contact's cell phone number origin."}
            end
        end
    end
end

module V1
    module Entities
        class Group < Grape::Entity
            expose :status_code, documentation: { type: "Integer", desc: "HTTP Status"}
            expose :response_type, documentation: { type: "String", desc: "Success or Failure"}
            expose :details, documentation: { type: "String", desc: "Message about the success."}
            expose :data, documentation: { type: "Array", desc: "Data array for the objects returned."} do 
                expose :id, documentation: { type: "Integer", desc: "Id of the group."}
                expose :name, documentation: { type: "String", desc: "Name of the group."}
                expose :description, documentation: { type: "String", desc: "Description about the group."}
                expose :organization_id, documentation: { type: "Integer", desc: "Id of the organization of the group."}
                expose :user_id, documentation: { type: "String", desc: "Id of the user that created the group. (default 0 for non-users)"}
                expose :created_at, documentation: { type: "DateTime", desc: "DateTime of when the group was created."}
                expose :updated_at, documentation: { type: "DateTime", desc: "DateTime of when the group was last updated."}
            end
        end
    end
end

module V1
    module Entities
        class Keyword < Grape::Entity
            expose :status_code, documentation: { type: "Integer", desc: "HTTP Status"}
            expose :response_type, documentation: { type: "String", desc: "Success or Failure"}
            expose :details, documentation: { type: "String", desc: "Message about the success."}
            expose :data, documentation: { type: "Array", desc: "Data array for the objects returned."} do
                expose :id, documentation: { type: "Integer", desc: "Id of the keyword."}
                expose :name, documentation: { type: "String", desc: "Name of the keyword."}
                expose :help_text, documentation: { type: "String", desc: "Help text response for the keyword."}
                expose :description, documentation: { type: "String", desc: "Description about the keyword."}
                expose :opt_in_text, documentation: { type: "String", desc: "Opt In text response for the keyword."}
                expose :opt_out_text, documentation: { type: "String", desc: "Opt Out text response for the keyword."}
                expose :organization_id, documentation: { type: "Integer", desc: "Organization id for the keyword."}
                expose :user_id, documentation: { type: "String", desc: "Id of the user that created the group. (default 0 for non-users)"}
                expose :created_at, documentation: { type: "DateTime", desc: "DateTime of when the keyword was created."}
                expose :updated_at, documentation: { type: "DateTime", desc: "DateTime of when the keyword was last updated."}
            end
        end
    end
end

module V1
    module Entities
        class Blast < Grape::Entity
            expose :status_code, documentation: { type: "Integer", desc: "HTTP Status"}
            expose :response_type, documentation: { type: "String", desc: "Success or Failure"}
            expose :details, documentation: { type: "String", desc: "Message about the success."}
            expose :data, documentation: { type: "Array", desc: "Data array for the objects returned."} do
                expose :id, documentation: { type: "Integer", desc: "Id of the message."}
                expose :message, documentation: { type: "String", desc: "Contents of the message."}
                expose :active, documentation: { type: "Boolean", desc: "Active status of the message."}
                expose :repeat, documentation: { type: "Boolean", desc: "Repeating status of the message."}
                expose :repeat_end_date, documentation: { type: "DateTime", desc: "Repeating end date and time of the message."}
                expose :send_date_time, documentation: { type: "DateTime", desc: "Send date and time of the message."}
                expose :sms, documentation: { type: "Boolean", desc: "SMS status of the message."}
                expose :keyword_id, documentation: { type: "Integer", desc: "Keyword id of the message."}
                expose :keyword_name, documentation: { type: "String", desc: "Keyword name of the message."}
                expose :organization_id, documentation: { type: "Integer", desc: "Organization id for the message."}
                expose :user_id, documentation: { type: "String", desc: "Id of the user that created the message. (default 0 for non-users)"}
                expose :cost, documentation: { type: "Float", desc: "Cost of the blast either in credits or dollars."}
                expose :rate, documentation: { type: "Integer", desc: "Concation rate for the message."}
                expose :contact_count, documentation: { type: "Integer", desc: "Number of contacts the blast was sent to."}
                expose :created_at, documentation: { type: "DateTime", desc: "DateTime of when the blast was created."}
                expose :updated_at, documentation: { type: "DateTime", desc: "DateTime of when the blast was last updated."}
            end
        end
    end
end

module V1
    module Entities
        class BlastAttachment < Grape::Entity
            expose :status_code, documentation: { type: "Integer", desc: "HTTP Status"}
            expose :response_type, documentation: { type: "String", desc: "Success or Failure"}
            expose :details, documentation: { type: "String", desc: "Message about the success."}
            expose :data, documentation: { type: "Array", desc: "Data array for the objects returned."} do
                expose :id, documentation: { type: "Integer", desc: "Id of the blast attachment."}
                expose :attachment, documentation: { type: "File", desc: "Attachment File Details."}
            end
        end
    end
end

module V1
    module Entities
        class ContactArray < Grape::Entity
            expose :status_code, documentation: { type: "Integer", desc: "HTTP Status"}
            expose :response_type, documentation: { type: "String", desc: "Success or Failure"}
            expose :details, documentation: { type: "String", desc: "Message about the success."}
            expose :data, documentation: { type: "Array", desc: "Data array for the objects returned."} do
                expose :contact_array, documentation: { type: "Array", desc: "Array of contact ids."}
            end
        end
    end
end

module V1
    module Entities
        class ContactArray < Grape::Entity
            expose :status_code, documentation: { type: "Integer", desc: "HTTP Status"}
            expose :response_type, documentation: { type: "String", desc: "Success or Failure"}
            expose :details, documentation: { type: "String", desc: "Message about the success."}
            expose :data, documentation: { type: "Array", desc: "Data array for the objects returned."} do
                expose :id, documentation: { type: "Integer", desc: "Contact Id."}
                expose :first_name, documentation: { type: "String", desc: "Contact first name."}
                expose :last_name, documentation: { type: "String", desc: "Contact last name."}
                expose :primary_email, documentation: { type: "String", desc: "Contact primary email."}
                expose :secondary_email, documentation: { type: "String", desc: "Contact secondary email."}
                expose :company_name, documentation: { type: "String", desc: "Contact company name."}
                expose :cell_phone, documentation: { type: "String", desc: "Contact cell phone number."}
                expose :active, documentation: { type: "Boolean", desc: "Contact active."}
            end
        end
    end
end

module V1
    module Entities
        class Survey < Grape::Entity
            expose :status_code, documentation: { type: "Integer", desc: "HTTP Status"}
            expose :response_type, documentation: { type: "String", desc: "Success or Failure"}
            expose :details, documentation: { type: "String", desc: "Message about the success."}
            expose :data, documentation: { type: "Array", desc: "Data array for the objects returned."} do 
                expose :id, documentation: { type: "Integer", desc: "Id of the survey."}
                expose :name, documentation: { type: "String", desc: "Name of the survey."}
                expose :description, documentation: { type: "String", desc: "Description about the survey."}
                expose :organization_id, documentation: { type: "Integer", desc: "Id of the organization of the survey."}
                expose :start_message, documentation: { type: "String", desc: "Starting message of the survey."}
                expose :completion_message, documentation: { type: "String", desc: "Completion message of the survey."}
                expose :submit_button_text, documentation: { type: "String", desc: "Submit button text of the survey."}
                expose :submit_text, documentation: { type: "Text", desc: "Submit area text of the survey."}
                expose :start_date_time, documentation: { type: "DateTime", desc: "DateTime of when the survey will start."}
                expose :end_date_time, documentation: { type: "DateTime", desc: "DateTime of when the survey will end."}
                expose :multiple_responses_allowed, documentation: { type: "Boolean", desc: "Does the survey allow multiple responses."}
                expose :created_at, documentation: { type: "DateTime", desc: "DateTime of when the survey was created."}
                expose :updated_at, documentation: { type: "DateTime", desc: "DateTime of when the survey was last updated."}
            end
        end
    end
end

module V1
    module Entities
        class SurveyQuestion < Grape::Entity
            expose :status_code, documentation: { type: "Integer", desc: "HTTP Status"}
            expose :response_type, documentation: { type: "String", desc: "Success or Failure"}
            expose :details, documentation: { type: "String", desc: "Message about the success."}
            expose :data, documentation: { type: "Array", desc: "Data array for the objects returned."} do 
                expose :id, documentation: { type: "Integer", desc: "Id of the question."}
                expose :survey_id, documentation: { type: "Integer", desc: "Id of the survey."}
                expose :question, documentation: { type: "String", desc: "Question prompt."}
                expose :detail, documentation: { type: "Text", desc: "Detail description about the survey question."}
                expose :max_range, documentation: { type: "String", desc: "If a rating question, the high rating title."}
                expose :min_range, documentation: { type: "String", desc: "If a rating question, low rating title."}
                expose :question_type, documentation: { type: "Integer", desc: "Internal question type id."}
                expose :required, documentation: { type: "Boolean", desc: "The survey question is required."}
                expose :created_at, documentation: { type: "DateTime", desc: "DateTime of when the question was created."}
                expose :updated_at, documentation: { type: "DateTime", desc: "DateTime of when the question was last updated."}
            end
        end
    end
end

module V1
    module Entities
        class SurveyResponse < Grape::Entity
            expose :status_code, documentation: { type: "Integer", desc: "HTTP Status"}
            expose :response_type, documentation: { type: "String", desc: "Success or Failure"}
            expose :details, documentation: { type: "String", desc: "Message about the success."}
            expose :data, documentation: { type: "Array", desc: "Data array for the objects returned."} do 
                expose :current_pagination, documentation: { type: "Integer", desc: "Current pagination iteration."}
                expose :total_responses, documentation: { type: "Integer", desc: "Number of responses for the survey to return."}
                expose :pagination_max, documentation: { type: "Integer", desc: "Maximum number of pagination iterations."}
                expose :response_csv
            end

            private 

            def response_csv
                "csv"
            end
        end
    end
end