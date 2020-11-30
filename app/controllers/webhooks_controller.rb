class WebhooksController < ApplicationController
    skip_before_action :verify_authenticity_token
    include SendGrid

    # Used for managing phone numbers

    def bandwidth_hook 
        results = params["_json"].first
        incoming_number = results["message"]["from"]
        incoming_number = incoming_number.gsub("+", "")
        receiving_number = results["to"]
        receiving_number = receiving_number.gsub("+","")
        message = results["message"]["text"]
        message_id = results["message"]["id"]

        logger.info("Params: #{params}")


        if incoming_number != "18664743663"
            MoJob.perform_async(incoming_number, receiving_number, "sms", message, message_id, nil, "bandwidth")
        end


    end


    def bandwidth_phone_order 
        logger.info "Received #{request.method.inspect} to #{request.url.inspect} from #{request.remote_ip.inspect}.  Processing with headers #{request.env['HTTP_MY_HEADER']} and params #{params.inspect} "

        # Bandwidth Returns XML in the body of a response
        # EX: <?xml version="1.0" encoding="UTF-8" standalone="yes"?><Notification><Status>COMPLETE</Status><SubscriptionId>9a434012-501b-4d7f-989d-fb64a4fcb74b</SubscriptionId><Message>Created a new number order for 1 number from Unknown RC, Unknown State</Message><OrderId>31d06aea-651b-42ba-a338-4e629800368d</OrderId><OrderType>orders</OrderType><CompletedTelephoneNumbers><TelephoneNumber>8338760878</TelephoneNumber></CompletedTelephoneNumbers></Notification>

        doc = Nokogiri::XML(request.body.read) 
        # Get the status of the response [COMPLETE, PARTIAL, BACKORDERED, FAILED] 
        # We are only interested in COMPLETE & FAILED

        bandwidth_status = doc.at_xpath("//Notification/Status").inner_text
        bandwidth_order_id = doc.at_xpath("//Notification/OrderId").inner_text
        logger.info "Status: #{bandwidth_status} Order ID: #{bandwidth_order_id}"
        if bandwidth_status == "COMPLETE"
            successful_order(bandwidth_order_id)
        elsif bandwidth_status == "FAILED"
            failed_order(bandwidth_order_id)
        end

        respond_to do |format|
            format.html
            format.json { render json: {"request":"#{request}", "params":"#{params}"}, status: :ok }
            format.xml {render xml: {}, status: :ok }
        end
    end

    def mgage_mo_hook
        head :ok

        logger.info("------> MO Params: #{params}")
        logger.info("-----> REQUEST: #{request.fullpath}")
        logger.info("---> body #{request.body}")
        logger.info("-----> RAW: #{request.raw_post}")
        logger.info("-----> Request Params: #{request.query_parameters}")
        device_id = params[:device_address]
        device_id = "+#{device_id}"
        inbound_number = params[:inbound_address]
        inbound_number = "+1#{inbound_number}"
        message_type = params[:channel]
        message = params[:message]
        mgage_message_id = params[:message_id]
        message_subid = params[:message_subid] # ordering long messages 

        phone_number = PhoneNumber.find_by_value(inbound_number)     
        
        if phone_number

            MoJob.perform_async(phone_number.id, device_id, mgage_message_id, message, "mgage")

        end
    end

    def mgage_dr_hook
        head :ok
    end

    private 

    def sendgrid_client 
        return  SendGrid::API.new(api_key: Rails.application.credentials.send_grid ).client
    end

    def create_email(template_id, email_array, template_data)
        mail = SendGrid::Mail.new        
        mail.template_id = template_id
        mail.from = Email.new(email: 'success@mobilizecomms.com')
        for email in email_array
            personalization = Personalization.new
            personalization.add_to(Email.new(email: email))
            personalization.add_dynamic_template_data(template_data)
            mail.add_personalization(personalization)
        end

        return mail
    end

    def successful_order(order_id)
        # 1. Find the existing order record in the system
        # 2. Update the order record with the new details 
        # 3. Create a New Phone Number record
        # 4. Create a New Phone Number ownership record 
        # 5. Create a New Source Relationship record
        # 6. Email/Text the user who created the number an update 

        # Step 1
        existing_phone_number_order = PhoneNumberOrder.find_by(aggregator_order_id: order_id)
        if !existing_phone_number_order
            logger.error("Failed to find an existing phone number order from Bandwidth: #{order_id}")
            Appsignal.set_error("Failed to find an existing phone number order from Bandwidth: #{order_id}")
            return
        end

        # Step 2
        existing_phone_number_order.aggregator_order_last_update = Time.now 
        existing_phone_number_order.aggregator_order_status = "SUCCESS"
        if !existing_phone_number_order.save 
            logger.error("Failed to update an existing phone number order record: #{existing_phone_number_order.errors.full_messages}")
            Appsignal.set_error("Failed to update an existing phone number order record: #{existing_phone_number_order.errors.full_messages}")
            return
        end

        # Step 3
        new_phone_number = PhoneNumber.new(aggregator: "bandwidth", aggregator_id: order_id, available: false, reserved: false, shared: false, value: existing_phone_number_order.phone_number, phone_type: "tollfree")

        if !new_phone_number.save 
            logger.error("Failed to create a new phone number from an existing phone number order record: #{new_phone_number.errors.full_messages}")

            Appsignal.set_error("Failed to create a new phone number from an existing phone number order record: #{new_phone_number.errors.full_messages}")
            return
        end

        # Step 4
        new_phone_ownership = PhoneNumberOwnership.new(phone_number_id: new_phone_number.id, parent_organization_id: existing_phone_number_order.parent_organization_id) 

        if !new_phone_ownership.save 
            logger.error("Failed to create a new phone number ownership from an existing phone number order record: #{new_phone_ownership.errors.full_messages}")

            Appsignal.set_error("Failed to create a new phone number ownership from an existing phone number order record: #{new_phone_ownership.errors.full_messages}")
            return
        end

        # Step 5
        source = Source.find_by(parent_organization_id: existing_phone_number_order.parent_organization_id, child_organization_id: nil)
        if !source 
            logger.error("Failed to find a source record for the Parent organization #{existing_phone_number_order.parent_organization_id} while creating a phone number record under phone id #{new_phone_number.id}.")

            Appsignal.set_error("Failed to find a source record for the Parent organization #{existing_phone_number_order.parent_organization_id} while creating a phone number record under phone id #{new_phone_number.id}.")
            return 
        end
        new_phone_source = SourcePhoneNumberRelationship.new(phone_number_ownership_id: new_phone_ownership.id, source_id: source.id) 

        if !new_phone_source.save 
            logger.error("Failed to create a new phone number ownership from an existing phone number order record: #{new_phone_ownership.errors.full_messages}")

            Appsignal.set_error("Failed to create a new phone number ownership from an existing phone number order record: #{new_phone_ownership.errors.full_messages}")
            return
        end

        # Step 6
        user_emails = []
        user = User.find_by_id(existing_phone_number_order.user_id)
        # On the rare case that the user who initiated the purchase is not available any more, then we will send to all users on the account. 
        if !user 
            sources = existing_phone_number_order.parent_organization.sources.where(child_organization_id: nil)
            for source in sources 
                for user_access in source.user_accesses
                    user_emails.push(user_access.user.email)
                end
            end
        else
            user_emails.push(user.email)
        end

        mail = create_email('d-116d829bd1ac41f5b41e0273e4fa08ad', user_emails, {
            "message" =>   "We have successfully allocated you a new phone number! Your new phone number is #{pretty_phone_number(new_phone_number.value)}",
            "subject" => "Mobilize Comms - New Phone Number Allocated"
        })

        response = sendgrid_client.mail._('send').post(request_body: mail.to_json)

        if response.status_code.to_i < 200 && response.status_code.to_i > 300
            Appsignal.set_error("Failed To Send New Phone Number Allocation Success Email: #{user_emails} | #{response.body} ")
            return
        end


    end

    def failed_order(order_id)
        # 1. Find the existing order record in the system 
        # 2. Update the order record with the new details 
        # 3. Request a new allocation for a phone number 
        # 4. Create a new phone number order record
        # 5. Email/Text the user who created the number an update

        # Step 1
        existing_phone_number_order = PhoneNumberOrder.find_by(aggregator_order_id: order_id)
        if !existing_phone_number_order
            Appsignal.set_error("Failed to find an existing phone number order from Bandwidth: #{order_id}")
            return
        end
 
        # Step 2
        existing_phone_number_order.aggregator_order_last_update = Time.now 
        existing_phone_number_order.aggregator_order_status = "FAILED"
        if !existing_phone_number_order.save 
            Appsignal.set_error("Failed to update an existing phone number order record: #{existing_phone_number_order.errors.full_messages}")
            return 
        end

        # Step 3 & 4
        parent_organization = ParentOrganization.find_by_id(existing_phone_number_order.parent_organization_id)
        if !parent_organization
            # Since the organization no longer exists we do not need to process the order.
            return
        end
        bandwidth = BandwidthMasterService.new()
        user_id = existing_phone_number_order.user_id 
        if !user_id 
            # TODO: User may not exist so we need to hand that. 
            return
        end
        new_phone_number_allocation = bandwidth.allocate_random_toll_free_number(user_id, existing_phone_number_order.parent_organization_id)
        if !new_phone_number_allocation[:success]
            Appsignal.set_error("Failed to allocate a new number after one has failed to allocate: Order ID: #{existing_phone_number_order.id}")
            return
        end

        # Step 5

        user_emails = []
        user = User.find_by_id(existing_phone_number_order.user_id)
        # On the rare case that the user who initiated the purchase is not available any more, then we will send to all users on the account. 
        if !user 
            sources = parent_organization.sources.where(child_organization_id: nil)
            for source in sources 
                for user_access in source.user_accesses
                    user_emails.push(user_access.user.email)
                end
            end
        else
            user_emails.push(user.email)
        end

        mail = create_email('d-116d829bd1ac41f5b41e0273e4fa08ad', user_emails, {
            "message" =>   "We are sorry but we could not allocate your phone number. Do not worry though, we have started alloacting a new one again for you.",
            "subject" => "Mobilize Comms - New Phone Number Allocation Update"
        })

        response = sendgrid_client.mail._('send').post(request_body: mail.to_json)

        if response.status_code.to_i < 200 && response.status_code.to_i > 300
            Appsignal.set_error("Failed To Send Failed New Phone Number Allocation Success Email: #{user_emails} | #{response.body} ")
            return
        end

    end

end
