include ApplicationHelper
include BlastHelper
include ContactsHelper

module V1
    class BLASTAPI < Grape::API
        resource :blast do

            ##--> Get A Blast <--##
            desc 'Returns A Blast Record',
            success: [
                { code: 200, message: "Blast has been returned.", mode: Entities::Blast }
            ],
            failure: [
                { code: 400, message: 'Bad request', model: Entities::ErrorResponse  },
                { code: 401, message: "Api Not Unauthorized", model: Entities::ErrorResponse  },
                { code: 404, message: 'Blast Not Found',  model: Entities::ErrorResponse }
            ]
            params do
                requires :id, type: Integer, desc: 'Blast Id Integer'
            end
            get ":id" do

                # Authenticate The Request
                authenticate!(request.headers["X-Api-Key"])

                existing_blast = @organization.blasts.find_by_id(params[:id])
                if existing_blast
                    status 200
                    return { status_code: 200, response_type: 'success', details: "Blast was found and returned.", data: existing_blast }
                else
                    status 404
                    return { status_code: 404, response_type: 'error', details: "Blast does not exist." }
                end
            end

            ##--> Get A Blast Attachments <--##
            desc 'Returns A Blast Attachment Records',
            success: [
                { code: 200, message: "Blast Attachments have been returned.", model: Entities::BlastAttachment }
            ],
            failure: [
                { code: 400, message: 'Bad request', model: Entities::ErrorResponse  },
                { code: 401, message: "Api Not Unauthorized", model: Entities::ErrorResponse  },
                { code: 404, message: 'Blast Not Found',  model: Entities::ErrorResponse }
            ]
            params do
                requires :id, type: Integer, desc: 'Blast Id Integer'
            end
            get ":id/blast_attachments" do
                # Authenticate The Request
                authenticate!(request.headers["X-Api-Key"])

                existing_blast = @organization.blasts.find_by_id(params[:id])
                if existing_blast
                    blast_attachments = existing_blast.blast_attachments
                    status 200
                    return { status_code: 200, response_type: 'success', details: "Blast was found and returning blast attachments.", data: blast_attachments }
                else
                    status 404
                    return { status_code: 404, response_type: 'error', details: "Blast does not exist." }
                end
            end

            ##--> Get A Blast Groups <--##
            desc 'Returns A Blast Group Records',
            success: [
                { code: 200, message: "Blast groups have been returned.", model: Entities::Group }
            ],
            failure: [
                { code: 400, message: 'Bad request', model: Entities::ErrorResponse  },
                { code: 401, message: "Api Not Unauthorized", model: Entities::ErrorResponse  },
                { code: 404, message: 'Blast Not Found',  model: Entities::ErrorResponse }
            ]
            params do
                requires :id, type: Integer, desc: 'Blast Id Integer'
            end
            get ":id/groups" do
                # Authenticate The Request
                authenticate!(request.headers["X-Api-Key"])

                existing_blast = @organization.blasts.find_by_id(params[:id])
                if existing_blast
                    blast_groups = existing_blast.groups
                    status 200
                    return { status_code: 200, response_type: 'success', details: "Blast was found and returning blast groups.", data: blast_groups }
                else
                    status 404
                    return { status_code: 404, response_type: 'error', details: "Blast does not exist." }
                end
            end

            ##--> Get A Blast Contacts <--##
            desc 'Returns A Blast Contacts Records',
            success: [
                { code: 200, message: "Blast contacts have been returned.", mode: Entities::Group }
            ],
            failure: [
                { code: 400, message: 'Bad request', model: Entities::ErrorResponse  },
                { code: 401, message: "Api Not Unauthorized", model: Entities::ErrorResponse  },
                { code: 404, message: 'Blast Not Found',  model: Entities::ErrorResponse }
            ]
            params do
                requires :id, type: Integer, desc: 'Blast Id Integer'
            end
            get ":id/contacts" do
                # Authenticate The Request
                authenticate!(request.headers["X-Api-Key"])

                existing_blast = @organization.blasts.find_by_id(params[:id])
                if existing_blast
                    blast_contacts = existing_blast.contact_ids
                    status 200
                    return { status_code: 200, response_type: 'success', details: "Blast was found and returning blast contacts.", data: { "contact_ids": blast_contacts }}
                else
                    status 404
                    return { status_code: 404, response_type: 'error', details: "Blast does not exist." }
                end
            end

            ##--> Delete Blast <--##
            desc 'Deletes an existing Blast that has not been sent.',
            success: [
                { code: 200, message: 'Blast has been delete.', model: Entities::ErrorResponse },
            ],
            failure: [
                { code: 400, message: 'Bad request', model: Entities::ErrorResponse  },
                { code: 401, message: "Api Not Unauthorized", model: Entities::ErrorResponse  },
                { code: 404, message: 'Keyword Not Found',  model: Entities::ErrorResponse }
            ]
            params do
                requires :id, type: Integer, desc: 'Blast Id', documentation: { param_type: "body" }
            end
            delete ":id" do

                # Authenticate The Request
                authenticate!(request.headers["X-Api-Key"])

                existing_blast = @organization.blasts.find_by_id(params[:id])

                if existing_blast

                    current_date_time = DateTime.now

                    if existing_blast.send_date_time > current_date_time
                        if existing_blast.destroy
                            status 200
                            return { status_code: 200, response_type: 'success', details: "Blast was deleted." }
                        end
                    else
                        status 400
                        return { status_code: 400, response_type: 'error', details: "You cannot delete blasts that have already been sent." }
                    end
                else
                    status 404
                    return { status_code: 404, response_type: 'error', details: "Blast does not exist." }
                end

            end

            ##--> Create Blast <--##
            desc 'Creates an Blast to be sent out to specified receipiants.',
            success: [
                { code: 200, message: 'Blast has been created.', model: Entities::Blast },
                { code: 229, message: 'SMS partial success. Not all contacts could be processed.', model: Entities::Blast }
            ],
            failure: [
                { code: 400, message: 'Bad request', model: Entities::ErrorResponse  },
                { code: 401, message: "Api Not Unauthorized", model: Entities::ErrorResponse  },
                { code: 404, message: 'Keyword Not Found',  model: Entities::ErrorResponse }
            ]
            params do
                requires :message, type: String, desc: 'Message Text', documentation: { param_type: "body" }
                optional :contacts, type: Array, desc: "Contact id array" do
                    requires :contact_id, type: Integer, desc: "Contact Id"
                end
                optional :contact_numbers, type: Array, desc: 'Cell Phone number array.' do
                    requires :cell_phone, type: String, desc: "Cell phone number of the contact."
                end
                optional :delivery_code, type: String, desc: 'Short or Long Code Used To Process Blast (will default to short code)'
                requires :keyword_id, type: Integer, desc: "Keyword id to attach the message with."
                optional :groups, type: Array, desc: "Group id array" do
                    requires :group_id, type: Integer, desc: "Group Id"
                end
                requires :immediate_send, type: Boolean, desc: "Immediately send the blast"
                optional :scheduled_date_time, type: DateTime, desc: "When should the blast be scheduled for in UTC DateTime"
                optional :media_url, type: String, desc: "Medai Url for your attachment. (Limit 1MB)"
            end

            post do

                # Items To Send Back
                status_set = 200
                errors = nil
                created_items = Array.new

                # Authenticate The Request
                authenticate!(request.headers["X-Api-Key"])

                # Delivery Code - The number to process the message through.
                delivery_code = params[:delivery_code]
                if !delivery_code
                    org_number_relationship = @organization.organization_phone_relationships.where(mass_outgoing: true).limit(1)
                    delivery_code = org_number_relationship.first.phone_number.real
                else
                    if !PhoneNumber.find_by_real(delivery_code)
                        ApiLog.create(api_method: "create_sms", request: request.url, header: headers, params: params, error_source: "Delivery Code Look Up", error: "Delivery Code does not exist.")
                        status 404
                        return { status_code: 404, response_type: 'error', details: "Delivery Code #{delivery_code} does not exist." }
                    end
                end

                # Find The Required Keyword
                keyword_id = params[:keyword_id]
                keyword = nil
                if keyword_id
                    keyword = Keyword.find_by_id(keyword_id)
                    if !keyword
                        status 404
                        return { status_code: 404, response_type: 'error', details: "Failed to find keyword by id: #{keyword_id}" }
                    end
                end

                # Filter Message To Ensure No Extra Characters Are Included
                filtered_message = BlastHelper::filter_message(params[:message])

                # Determine SMS or MMS
                sms = true
                if params[:media_url]
                    sms = false
                end

                # Determine Message Rate if SMS
                rate = 1
                if sms
                    rate = BlastHelper::sms_rate_check(filtered_message)
                end

                b = nil # Used for blast reporting after the action record

                ApplicationRecord.transaction do

                    # Create The Contact Array (Contact Ids, Contact Numbers, Group Ids)
                    total_contact_array = Array.new

                    ## Process New Contacts & Contact Numbers
                    contact_numbers = params[:contact_numbers]
                    if contact_numbers
                        for contact_number in contact_numbers
                            cell_phone = contact_number["cell_phone"]
                            if cell_phone
                                # Filter The Phone Number
                                filtered_cell_phone = ContactsHelper::strip_number(cell_phone)
                                # Determine If It Is A Contact
                                existing_contact = @organization.contacts.find_by_cell_phone(filtered_cell_phone)
                                if existing_contact
                                    total_contact_array.push(existing_contact)
                                else
                                    # Contact does not exist so lets create it
                                    new_contact = Contact.new(cell_phone: filtered_cell_phone, organization_id: @organization.id, user_id: 0)
                                    if !new_contact.save
                                        # Log Envent
                                        ApiLog.create(api_method: "create_blast", request: request.url, header: headers, params: params, error_source: "New User Save", error: b.errors.full_messages)
                                        status_set = 400
                                        errors = "Failed to create new contact record. #{new_contact.errors.full_messages.join(".")}"
                                        raise ActiveRecord::Rollback
                                    end
                                    total_contact_array.push(new_contact)
                                end
                            end
                        end
                    end

                    # Process The Contact Array Of Ids
                    contact_array = params[:contacts]
                    if contact_array
                        for contact in contact_array
                            # Find The Contact
                            found_contact = @organization.contacts.find_by_id(contact["contact_id"])
                            if found_contact
                                total_contact_array.push(found_contact)
                            else
                                # Log Envent
                                status_set = 404
                                errors = "Failed to find contact #{contact["contact_id"]}."
                                raise ActiveRecord::Rollback
                            end
                        end
                    end

                    # Process The Group Ids
                    group_array = params[:groups]
                    if group_array
                        for group in group_array
                            # Find the group
                            found_group = @organization.groups.find_by_id(group["group_id"])
                            if found_group
                                total_contact_array += found_group.contacts
                            else
                                status_set = 404
                                errors = "Failed to find group #{group["group_id"]}."
                                raise ActiveRecord::Rollback
                            end
                        end
                    end

                    # Optional Items
                    ## Send Date Time
                    immediate_send = params[:immediate_send]
                    send_date_time = DateTime.now
                    if !immediate_send
                        send_date_time = params[:scheduled_date_time]
                        if !send_date_time
                            status_set = 404
                            errors = "A scheduled date time has to be provided for blasts that are not being send immediately."
                            raise ActiveRecord::Rollback
                        end
                        if send_date_time <= DateTime.now
                            status_set = 400
                            errors = "A scheduled date time has to be in the future."
                            raise ActiveRecord::Rollback
                        end
                    end

                    # Process A Media File
                    media_file = nil
                    media_url = params[:media_url]
                    if media_url
                        rate = 3
                        begin
                            media_file = Down.download(media_url, max_size: (1*1024*1024)) # 1 MB Limit
                        rescue => exception
                            status_set = 400
                            errors = "A media file cannot be larger than 1MB."
                            raise ActiveRecord::Rollback
                        end
                    end

                    # Unique The Contact Array
                    total_contact_array = total_contact_array.uniq

                    # Determine If The Account Has Enough Credits 
                    current_usage = @organization.current_credit_usage
                    remaining =  @organization.credits_left

                    if remaining < 0
                        status_set = 400
                        errors = "Not Enough Credits To Process This Blast. Please Upgrade"
                        raise ActiveRecord::Rollback
                    end



                    # Create The Blast Record
                    b = Blast.new(active: true, sms: sms, keyword_id: keyword.id, keyword_name: keyword.name, message: filtered_message, send_date_time: send_date_time, user_id: 0, organization_id: @organization.id, contact_count: total_contact_array.count, cost: total_contact_array.count * rate, rate: rate)

                    if !b.save
                        # Log Envent
                        ApiLog.create(api_method: "create_blast", request: request.url, header: headers, params: params, error_source: "Blast Save", error: b.errors.full_messages)
                        status_set = 400
                        errors = "Failed to create message record. #{b.errors.full_messages.join(".")}"
                        raise ActiveRecord::Rollback
                    end

                    # Attachments
                    if media_file
                        blast_attachment = BlastAttachment.new(blast_id: b.id, attachment: media_file)
                        if !blast_attachment.save
                            # Log Envent
                            ApiLog.create(api_method: "create_blast", request: request.url, header: headers, params: params, error_source: "Blast Attachment Save", error: blast_attachment.errors.full_messages)
                            status_set = 400
                            errors = "Failed to create blast attachment record. #{blast_attachment.errors.full_messages.join(".")}"
                            raise ActiveRecord::Rollback
                        end
                    end

                    # Create Contact + Blast Relationships
                    for c in total_contact_array

                        bcr = BlastContactRelationship.new(blast_id: b.id, contact_id: c.id, contact_number: c.cell_phone, status: "Iniated")

                        if !bcr.save
                            ApiLog.create(api_method: "create_sms", request: request.url, header: headers, params: params, error_source: "Blast Contact Relationship Save", error: bcr.errors.full_messages.join("."))
                            status_set = 400
                            errors = "Failed to create  and contact record. #{bcr.errors.full_messages.join(".")}"
                            raise ActiveRecord::Rollback
                        end
                    end

                    # Create Blast + Group Relationships
                    if group_array
                        for g in group_array
                            bgrp = BlastGroupRelationship.new(blast_id: b.id, group_id: g["group_id"])
                            if !bgrp.save
                                ApiLog.create(api_method: "create_blast", request: request.url, header: headers, params: params, error_source: "Blast Group Relationship Save", error: bgrp.errors.full_messages.join("."))
                                status_set = 400
                                errors = "Failed to create  and contact record. #{bgrp.errors.full_messages.join(".")}"
                                raise ActiveRecord::Rollback
                            end
                        end
                    end


                    # Send The Blast
                    if immediate_send
                        BlastHelper::set_blast_job(@organization.id, b, nil)
                    else
                        BlastHelper::set_blast_job(@organization.id, b, send_date_time)
                    end
                end


                # Return The Status & Results
                if status_set == 200
                    return { status_code: status_set, response_type: "success", details: "SMS Message created and sent.", data:  b}
                else
                    return { status_code: status_set, response_type: "failure", details: errors,  data: nil}
                end

            end



        end
    end
end
