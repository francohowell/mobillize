include ApplicationHelper
include ContactsHelper

module V1
    class CONTACTAPI < Grape::API
        resource :contacts do
            ##--> Create Contacts <--##
            desc 'Creates a single contact or mulitple contacts.' do
                success Entities::Contact
                failure [
                    [400, 'Bad request', Entities::ErrorResponse ],
                    [401, "Api Not Unauthorized", Entities::ErrorResponse  ],
                    [404, 'Contact Not Found', Entities::ErrorResponse ]
                ]
                is_array true
            end
            params do
                requires :contacts, type: Array,  documentation: { param_type: 'body' }  do 
                    requires :cell_phone, type: String, desc: 'String of Contact Cell Phone Number'
                    optional :active, type: Boolean, desc: 'Boolean representing active contact. Default: true'
                    optional :company_name, type: String, desc: 'String of the company name of the contact.'
                    optional :first_name, type: String, desc: 'String of the first name of the contact.'
                    optional :last_name, type: String, desc: 'String of the last name of the contact.'
                    optional :primary_email, type: String, desc: 'String of the primary email of the contact.'
                    optional :secondary_email, type: String, desc: 'String of the secondary email of the contact.'
                end
            end
            post do 

                # Items To Send Back 
                status_set = 200
                errors = nil 
                created_items = Array.new

                # Authenticate The Request
                authenticate!(request.headers["X-Api-Key"]) 

                # Begin The Transaction
                ApplicationRecord.transaction do

                    begin

                        for new_possible_contact in params[:contacts]

                            cell_phone = new_possible_contact[:cell_phone]
                            active = new_possible_contact[:active]
                            company_name = new_possible_contact[:company_name]
                            first_name = new_possible_contact[:first_name]
                            last_name = new_possible_contact[:last_name]
                            primary_email = new_possible_contact[:primary_email]
                            secondary_email = new_possible_contact[:secondary_email]

                            if !cell_phone
                                status_set = 400 
                                errors = "Cell phone is missing from contact." 
                                raise ActiveRecord::Rollback 
                            end

                            parsed_cell_phone = contact_parser([cell_phone])
                            cell_phone = parsed_cell_phone.first.gsub("+", "")

                            existing_contact = @organization.contacts.find_by_cell_phone(cell_phone)
                            if existing_contact
                                created_items.push(existing_contact)
                                next
                            end 

                            if active
                                if active.instance_of? String
                                    active = active.downcase
                                    active = active == "true" ? true : false 
                                end
                            else
                                active = true 
                            end

                            new_contact = Contact.new(cell_phone: cell_phone, active: active, company_name: company_name, first_name: first_name, last_name: last_name, primary_email: primary_email, secondary_email: secondary_email, user_id: 0, organization_id: @organization.id)

                            if new_contact.save! 
                                created_items.push(new_contact)
                            end
                        end
                    
                    rescue ActiveRecord::RecordInvalid => e
                       
                        status_set = 400 
                        errors = e 
                        ApiLog.create(api_method: "create_contact", request: request.url, header: headers, params: params, error_source: "Contact Save", error: new_contact.errors.full_messages.join(".")) 

                        raise ActiveRecord::Rollback 

                    end
                end

                
                # Return The Status & Results
                status status_set 
                if status_set == 200
                    return { status_code: status_set, response_type: "success", details: "Contats Created.", data:  created_items}
                else
                    return { status_code: status_set, response_type: "failure", details: errors,  data: nil}
                end
                
            end
            ##--> Create Contact <--##

            ##--> Delete Contact By Cell Phone<--##
            desc 'Deletes multiple contacts by their cell phone number.' do 
                success Entities::ErrorResponse
                failure [
                    [400, 'Bad request', Entities::ErrorResponse ],
                    [401, "Api Not Unauthorized", Entities::ErrorResponse  ],
                    [404, 'Contact Not Found', Entities::ErrorResponse ]
                ]
                is_array true
            end
            params do
                requires :contacts, type: Array, documentation: { param_type: 'body' } do 
                    requires :cell_phone, type: String, desc: "Cell phone number of the contact."
                end
            end
            post "delete_by_cell_phones" do 

                # Items To Send Back 
                status_set = 200
                errors = nil 


                # Authenticate The Request
                authenticate!(request.headers["X-Api-Key"])

                # Begin The Transaction
                ApplicationRecord.transaction do

                    for contact_number in params[:contacts]
                        cell_phone = contact_number[:cell_phone]

                        if !cell_phone
                            status_set = 400 
                            errors = "Cell phone is missing from contact." 
                            raise ActiveRecord::Rollback 
                        end

                        parsed_cell_phone = contact_parser([cell_phone])
                        cell_phone = parsed_cell_phone.first.gsub("+", "")

                        existing_contact = Contact.find_by_cell_phone(cell_phone)
                        if existing_contact

                            if existing_contact.destroy!
                                status_set = 200 
                            else
                                status_set = 400 
                                errors = "Contact could not be deleted. #{existing_contact.errors.full_messages.join(".")}" 
                                raise ActiveRecord::Rollback 
                            end
                        else 
                            status_set = 404 
                            errors = "Contact could not be found #{cell_phone}" 
                            raise ActiveRecord::Rollback 
                        end 
                    end 
                end

                 # Return The Status & Results
                 status status_set 
                 if status_set == 200
                     return { status_code: status_set, response_type: "success", details: "Contacts Were Deleted."}
                 else
                     return { status_code: status_set, response_type: "failure", details: errors,  data: nil}
                 end
            end
            ##--> Delete Contact By Cell Phone<--##

            ##--> Delete Contact <--##
            desc 'Deletes contacts by their ids.' do 
                success Entities::ErrorResponse
                failure [
                    [400, 'Bad request', Entities::ErrorResponse ],
                    [401, "Api Not Unauthorized", Entities::ErrorResponse  ],
                    [404, 'Contact Not Found', Entities::ErrorResponse ]
                ]
                is_array true
            end
            params do
                requires :contacts, type: Array, documentation: { param_type: 'body' } do 
                    requires :id, type: Integer, desc: "Id of the contact."
                end
            end
            post "delete" do 

                # Items To Send Back 
                status_set = 200
                errors = nil 


                # Authenticate The Request
                authenticate!(request.headers["X-Api-Key"])

                # Begin The Transaction
                ApplicationRecord.transaction do

                    for contact_id in params[:contacts]
                        id = contact_id[:id]

                        if !id
                            status_set = 400 
                            errors = "Id is missing from contact." 
                            raise ActiveRecord::Rollback 
                        end

                        existing_contact = Contact.find_by_id(id)
                        if existing_contact

                            if existing_contact.destroy!
                                status_set = 200 
                            else
                                status_set = 400 
                                errors = "Contact could not be deleted. #{existing_contact.errors.full_messages.join(".")}" 
                                raise ActiveRecord::Rollback 
                            end
                        else 
                            status_set = 404 
                            errors = "Contact could not be found: #{id}" 
                            raise ActiveRecord::Rollback 
                        end 
                    end 
                end

                 # Return The Status & Results
                 status status_set 
                 if status_set == 200
                     return { status_code: status_set, response_type: "success", details: "Contacts Were Deleted."}
                 else
                     return { status_code: status_set, response_type: "failure", details: errors,  data: nil}
                 end
            end
            ##--> Delete Contact <--##
        end

        resource :contact do
            
            ##--> Get Contact <--##
            desc 'Retreaves a Contact.' do
                success  Entities::Contact
                failure [
                    [ 400,'Bad request', Entities::ErrorResponse  ],
                    [ 401, "Api Not Unauthorized", Entities::ErrorResponse  ],
                    [ 404, 'Contact Not Found', Entities::ErrorResponse ]
                ]
                headers "X-Api-Key": {
                    description: 'Validates your identity',
                    required: true
                }
                params "id": {
                    type: Integer, 
                    desc: 'Contact Id Integer',
                    required: true
                }
            end
            get ":id" do 

                # Authenticate The Request
                authenticate!(request.headers["X-Api-Key"])

                existing_contact = Contact.find_by_id(params[:id])
                if existing_contact

                    if existing_contact
                        status 200 
                        return {status_code: 200, response_type: 'success', details: "Contact was found and returned.", data: [existing_contact] }
                    end
                else 
                    status 404 
                    return { status_code: 404, response_type: 'error', details: "Contact does not exist." }
                end         
            end

            ##--> Update Contact <--##
            desc 'Updates a Contact.' do 
                success  Entities::Contact
                failure [
                    [ 400,'Bad request', Entities::ErrorResponse  ],
                    [ 401, "Api Not Unauthorized", Entities::ErrorResponse  ],
                    [ 404, 'Contact Not Found', Entities::ErrorResponse ]
                ]
                headers "X-Api-Key": {
                    description: 'Validates your identity',
                    required: true
                }
                params "id": {
                    type: Integer, 
                    desc: 'Contact Id Integer',
                    required: true
                },
                "first_name": {
                    type: String, 
                    desc: "First name of the contact."
                },
                "last_name": {
                    type: String, 
                    desc: "Last name of the contact."
                },
                "company_name": {
                    type: String, 
                    desc: "Company the contact belongs to."
                },
                "cell_phone": {
                    type: String, 
                    desc: "Cell phone number of the contact."
                },
                "primary_email": {
                    type: String, 
                    desc: "Primary email of the contact."
                },
                "secondary_email": {
                    type: String, 
                    desc: "Secondary email of the contact."
                }
            end
            post ":id" do 

                # Authenticate The Request
                authenticate!(request.headers["X-Api-Key"])

                existing_contact = Contact.find_by_id(params[:id])
                if existing_contact
                    
                    if params[:first_name]
                        existing_contact.first_name = params[:first_name]
                    end

                    if params[:last_name] 
                        existing_contact.last_name = params[:last_name]
                    end

                    if params[:company_name]
                        existing_contact.company_name = params[:company_name]
                    end

                    if params[:cell_phone]
                        parsed_cell_phone = ContactsHelper::strip_number(params[:cell_phone])
                        existing_contact.cell_phone = parsed_cell_phone
                    end

                    if params[:primary_email] 
                        existing_contact.primary_email = params[:primary_email]
                    end

                    if params[:secondary_email] 
                        existing_contact.secondary_email = params[:secondary_email]
                    end

                    if existing_contact.save
                        status 200 
                        return { status_code: 200, response_type: 'success', details: "Contact was updated.", data: [existing_contact] }
                    else
                        status 400 
                        return { status_code: 400, response_type: 'failure', details: "Contact failed to be updated. #{existing_contact.errors.full_messages}" }
                    end
                else 
                    status 404 
                    return { status_code: 404, response_type: 'error', details: "Contact does not exist." }
                end         
            end


            ##--> Delete Contact <--##
            desc 'Deletes a Contact.' do
                success Entities::ErrorResponse
                failure [
                    [ 400,'Bad request', Entities::ErrorResponse  ],
                    [ 401, "Api Not Unauthorized", Entities::ErrorResponse  ],
                    [ 404, 'Contact Not Found', Entities::ErrorResponse ]
                ]
                headers "X-Api-Key": {
                    description: 'Validates your identity',
                    required: true
                }
                params "id": {
                    type: Integer, 
                    desc: 'Contact Id Integer',
                    required: true
                }
            end
            delete ":id" do 

                # Authenticate The Request
                authenticate!(request.headers["X-Api-Key"])

                existing_contact = Contact.find_by_id(params[:id])
                if existing_contact

                    if existing_contact.destroy
                        status 200 
                        return { status_code: 200, response_type: 'success', details: "Contact was deleted." }
                    else
                        status 400 
                        return { status_code: 400, response_type: 'error', details: "Contact could not be deleted. #{existing_contact.errors.full_messages.join(".")}" }
                    end
                else 
                    status 404 
                    return { status_code: 404, response_type: 'error', details: "Contact does not exist." }
                end         
            end
        end
    end
end