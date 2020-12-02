module V1
    class SURVEYAPI < Grape::API
        resource :survey do 

            ##--> Retreaves A Single Survey <--##
            desc 'Retreaves a Survey.',
            success: [
                { code: 200, message: 'Survey has been returned.', model: Entities::Survey },
            ],
            failure: [
                { code: 400, message: 'Bad request', model: Entities::ErrorResponse  },
                { code: 401, message: "Api Not Unauthorized", model: Entities::ErrorResponse  },
                { code: 404, message: 'Survey Not Found',  model: Entities::ErrorResponse }
            ]
            params do
                requires :id, type: Integer, desc: 'Survey id number.'
            end
            get ":id" do
                # Authenticate The Request
                authenticate!(request.headers["X-Api-Key"])

                survey_id = params[:id]

                if !survey_id
                    status 400 
                    return { status_code: 400, response_type: 'error', details: "Survey id is missing." }
                end

                existing_survey = @organization.surveys.find_by_id(survey_id)
                if existing_survey
                    status 200 
                    return { status_code: 200, response_type: 'success', details: "Survey was found.", data: existing_survey }
                else 
                    status 404 
                    return { status_code: 404, response_type: 'error', details: "Survey does not exist." }
                end
                
            end

            ##--> Retreaves Keyword <--##
            desc 'Retreaves a Survey Questions.',
            success: [
                { code: 200, message: 'Survey questions have been returned.', model: Entities::SurveyQuestion },
            ],
            failure: [
                { code: 400, message: 'Bad request', model: Entities::ErrorResponse  },
                { code: 401, message: "Api Not Unauthorized", model: Entities::ErrorResponse  },
                { code: 404, message: 'Survey Not Found',  model: Entities::ErrorResponse }
            ]
            params do
                requires :id, type: Integer, desc: 'Survey id number.'
            end
            get ":id/survey_questions" do
                # Authenticate The Request
                authenticate!(request.headers["X-Api-Key"])

                survey_id = params[:id]

                if !survey_id
                    status 400 
                    return { status_code: 400, response_type: 'error', details: "Survey id is missing." }
                end

                existing_survey = @organization.surveys.find_by_id(survey_id)
                survey_questions = existing_survey.survey_questions
                survey_questions.map do |question| 
                    if !ActiveSupport::TimeZone.us_zones.include?(@organization.timezone)
                        question.min_range = Date.strptime(question.min_range, '%m/%d/%Y').strftime('%d-%m-%Y') rescue ''
                        question.max_range = Date.strptime(question.max_range, '%m/%d/%Y').strftime('%d-%m-%Y') rescue ''
                    end
                end

                if existing_survey
                    status 200 
                    return { status_code: 200, response_type: 'success', details: "Survey was found.", data: survey_questions }
                else 
                    status 404 
                    return { status_code: 404, response_type: 'error', details: "Survey does not exist." }
                end
                
            end

            ##--> Retreaves A Survey's Responses <--##
            desc 'Retreaves a Survey Responses.',
            success: [
                { code: 200, message: 'Survey responses have been returned.', model: Entities::SurveyResponse },
            ],
            failure: [
                { code: 400, message: 'Bad request', model: Entities::ErrorResponse  },
                { code: 401, message: "Api Not Unauthorized", model: Entities::ErrorResponse  },
                { code: 404, message: 'Survey Not Found',  model: Entities::ErrorResponse }
            ]
            params do
                requires :id, type: Integer, desc: 'Survey id number.'
            end
            get ":id/survey_responses" do
                # Authenticate The Request
                authenticate!(request.headers["X-Api-Key"])

                survey_id = params[:id]

                if !survey_id
                    status 400 
                    return { status_code: 400, response_type: 'error', details: "Survey id is missing." }
                end

                existing_survey = @organization.surveys.find_by_id(survey_id)
                if existing_survey
                    status 200 
                    return { status_code: 200, response_type: 'success', details: "Survey was found.", data: { response_csv: existing_survey.response_csv } }
                else 
                    status 404 
                    return { status_code: 404, response_type: 'error', details: "Survey does not exist." }
                end
                
            end

            ##--> Retreaves A Survey's Responses <--##
            desc 'This API method will return a survey\'s responses in a paginated set. The pagination is based on sets of 20 responses. The first pagination will include a extra row of data that will define the header for the csv. Each additional pagination will only include the responses to be returned.',
            success: [
                { code: 200, message: 'Survey responses have been returned.', model: Entities::SurveyResponse },
            ],
            failure: [
                { code: 400, message: 'Bad request', model: Entities::ErrorResponse  },
                { code: 401, message: "Api Not Unauthorized", model: Entities::ErrorResponse  },
                { code: 404, message: 'Survey Not Found',  model: Entities::ErrorResponse }
            ]
            params do
                requires :id, type: Integer, desc: 'Survey id number.'
                requires :paginate_iteration, type: Integer, desc: 'Pagination value. 1 for the first 20, 2 for next 20, etc.'
                optional :pagination_set, type: Integer, desc: 'The pagination set of records. A maximum of 150.'
                optional :date_format, type: String, desc: 'This determines how your date fields will be returned. Default: YYYY-MM-DD Possible Options: YYYY-MM-DD YYYY/MM/DD MM-DD-YYYY MM/DD/YYYY DD-MM-YYYY DD/MM/YYYY'
                optional :include_time, type: Boolean, desc: "If you would like the time included with your dates please provide this as true. Time is reported as HH:MM:SS Timezone"

            end
            get ":id/survey_responses/:paginate_iteration" do
                # Authenticate The Request
                authenticate!(request.headers["X-Api-Key"])

                survey_id = params[:id]
                pagination_value = params[:paginate_iteration]
                pagination_set = params[:pagination_set]
                date_format = params[:date_format]
                include_time = params[:include_time]

                if !survey_id
                    status 400 
                    return { status_code: 400, response_type: 'error', details: "Survey id is missing." }
                end

                if !pagination_value
                    status 400 
                    return { status_code: 400, response_type: 'error', details: "Paginate Interation is missing." }
                end

                if pagination_value < 1
                    status 400 
                    return { status_code: 400, response_type: 'error', details: "Paginate Interation must be greater than 0." }
                end

                if !pagination_set
                    pagination_set = 20
                else 
                    if pagination_set > 150 
                        return { status_code: 400, response_type: 'error', details: "Paginate Set must be less than 150." }
                    elsif pagination_set <= 0 
                        return { status_code: 400, response_type: 'error', details: "Paginate Set must be greater than 0." }
                    end
                end

                structured_date = "%Y-%m-%d"
                if date_format
                    if !['YYYY-MM-DD', 'YYYY/MM/DD', 'MM-DD-YYYY', 'MM/DD/YYYY', 'DD-MM-YYYY', 'DD/MM/YYYY'].include?(date_format)
                        return { status_code: 400, response_type: 'error', details: "Date format did match any of the approved formats. Please use YYYY-MM-DD YYYY/MM/DD MM-DD-YYYY MM/DD/YYYY DD-MM-YYYY DD/MM/YYYY" }
                    else
                        case date_format
                        when "YYYY-MM-DD"
                            structured_date = "%Y-%m-%d"
                        when "YYYY/MM/DD"
                            structured_date = "%Y/%m/%d"
                        when "MM-DD-YYYY"
                            structured_date = "%m-%d-%Y"
                        when "MM/DD/YYYY"
                            structured_date = "%m/%d/%Y"
                        when "DD-MM-YYYY"
                            structured_date = "%d-%m-%Y"
                        when "DD/MM/YYYY"
                            structured_date = "%d/%m/%Y"
                        else
                            structured_date = "%Y-%m-%d"
                        end
                    end
                end

                if include_time == true 
                    structured_date += " %H:%M:%S %z"
                end
                

                existing_survey = @organization.surveys.find_by_id(survey_id)
                if existing_survey
                    total_records = existing_survey.survey_responses.count
                    status 200 
                    return { status_code: 200, response_type: 'success', details: "Survey was found.", data: { current_pagination: pagination_value, total_responses: total_records, pagination_max: (total_records/pagination_set).ceil, response_csv: existing_survey.paginate_csv_results(pagination_value, pagination_set, structured_date) } }
                else 
                    status 404 
                    return { status_code: 404, response_type: 'error', details: "Survey does not exist." }
                end
                
            end

        end

        resource :surveys do 
            ##--> Retreaves All Surveys <--##
            desc 'Retreaves all Surveys.',
            success: [
                { code: 200, message: 'Surveys have been returned.', model: Entities::Survey },
            ],
            failure: [
                { code: 400, message: 'Bad request', model: Entities::ErrorResponse  },
                { code: 401, message: "Api Not Unauthorized", model: Entities::ErrorResponse  },
                { code: 404, message: "Surveys not found.", model: Entities::ErrorResponse  }
            ]
            get do
                # Authenticate The Request
                authenticate!(request.headers["X-Api-Key"])
                existing_surveys = @organization.surveys
                if existing_surveys
                    status 200 
                    return { status_code: 200, response_type: 'success', details: "Surveys were found.", data: existing_surveys }
                else 
                    status 404 
                    return { status_code: 404, response_type: 'error', details: "Surveys do not exist." }
                end
                
            end
        end
        
    end
end