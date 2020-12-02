require 'bcrypt'
require "grape-swagger"

module V1
    class API < Grape::API

        version 'v1', using: :header, vendor: 'mobilizecomms', :format => :json
        format :json
        prefix :api

        helpers do

            def logger
                Rails.logger
            end


            def authenticate!(key)
                authorization = ApiAuthorization.find_by_key(key)
                if !authorization
                    error!({ status_code: 401, response_type: 'failure', details: "API was not authorized." }, 401)
                else
                    @organization = authorization.organization
                end
            end

            def contact_parser(contact_array)
                new_contact_array = Array.new
                for contact_number in contact_array
                    # Pull out all non-numeric characters
                    stripped_number = contact_number.gsub(/[^0-9]/, '')
                    if stripped_number.length == 10
                        stripped_number = "+1#{stripped_number}"
                    else
                        stripped_number = "+#{stripped_number}"
                    end
                    new_contact_array.push(stripped_number)
                end
                return new_contact_array
            end

        end

        mount V1::BLASTAPI
        mount V1::CONTACTAPI
        mount V1::GROUPAPI
        mount V1::KEYWORDAPI
        mount V1::SURVEYAPI

        get :test_authorization do
            # Authenticate The Request
            authenticate!(request.headers["X-Api-Key"])
        end

        add_swagger_documentation(
            api_version: "v1",
            hide_documentation_path: true,
            mount_path: "/swagger_doc",
            hide_format: true,
            # base_path: "http://localhost:3000/api",
            info: {
                title: "Mobilize Comms API Documentation.",
                description: "The Mobilize Comms Public API allows for programmatic use of the Mobilize Comms system. We do not charge the api calls and we currently do not limit the amount of calls that can be made by our users. You will still be charged for messages that are sent through the API. In addition to the methods below, you will need to provide your api authorization key in the header of your calls with the key X-Api-Key.",
                contact_name: "Mobilize Comms | Blueprint 108 LLC",
                contact_email: "support@mobilizecomms.com",
                contact_url: "https://mobilizecomms.com/",
                terms_of_service_url: "https://mobilizecomms.com/terms_conditions",
            },
            array_use_braces: true,
            doc_version: '2.0.3',
            security_definitions: {
                ApiKeyAuth:{
                  type: "apiKey",
                  name: "X-Api-Key",
                  in: "header",
                  description: "Requests should pass an api_key header."
                }
            },
            security: [{ ApiKeyAuth: [] }],
        )
    end

end
