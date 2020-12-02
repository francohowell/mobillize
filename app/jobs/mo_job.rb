# frozen_string_literal: true
class MoJob
    include Sidekiq::Worker
    sidekiq_options queue: 'default'
    include PaymentProcessor

    attr_reader :mgageService
    attr_reader :bandwidth

    def initialize()
      @mgageService = MgageMasterService.new()
      @bandwidth = BandwidthMasterService.new()
    end

    def perform(device_id, inbound_number, message_type, message, mgage_message_id, message_subid, carrier)

      #-> PSUEDO Code <-#
      # Parse the incoming message
      # Obtain the organization from the inbound_number
      # If no organization is found
      ## Send back a message to the device_id that the phone number is no longer in use
      ## Return
      # Use the device_id to search against the user accounts attached to the organization
      # If a user of the organization exists with the device_id and can_send_blasts
      ## Determine the credit rate of the parsed message
      ## If no keyword was provided in the parsed message
      ### Collect all the contacts of the organization that are marked active
      ## If a keyword was provided in the parsed message
      ### Collect all the active contacts that are part of the groups that are attached to the keyword
      ## Determine if the organization has enough credits to process the message by multiplying the number of contacts against the credit rate of the messge
      ## If the organization does not have enough credits to process the message
      ### Send a message back to the user that we cannnot process their blast as they do not have enough credits
      ### Return
      ## Create a blast with the message that was provided
      ## Create blast contact relationships with the contacts and the blast
      ## Execute the blast Job
      ## Return
      # If a user of the organization does not exists with the device_id
      ## Determine if the device_id is a contact (using cell_phone) of the organizaiton
      ## If a contact does not exist
      ### Create a new contact under the organization
      ## If no keyword was provided in the parsed message
      ### If this was a new contact
      #### Create + Execute a blast that sends the new contact the default opt-in message
      #### Return
      ### If this was not a new contact
      #### Record the response
      #### Return
      ## If a keyword was provided in the parsed message
      ### If the keyword OR the second word of the message is an opt-out keyword
      #### Process the opt-out
      #### Return
      ### If the keyword OR the second word of the message is a help keyword
      #### Process the help
      #### Return
      ### If the keyword is attached to any surveys
      #### Generate the start_message for all the surveys attached to the keyword
      #### Create + Execute a blast that sends the contact the start_message
      #### Return
      ### If the keyword is not attached to any surveys
      #### If the keyword has an opt_in message
      ##### Create + Execute a blast that sends the contact the keywords opt-out message
      ##### Return
      #### If the keyword has NO opt_in message
      ##### Create + Execute a blast that sends the contact the default system opt-out message
      ##### Return


      logger.info("Incoming Message: #{message}")
      #----> NEW <----#
      if !message || message.blank?
        @mgageService.system_message(SystemValue.find_by_key("empty_message_response").value, nil, device_id, inbound_number)
      else
        parsed_message_results = parse(message) # Parse out the message and the keyword (if there is a keyword)
        logger.info(parsed_message_results)

        # No Keyword was provided in the message.
        if parsed_message_results["keyword"].nil?

          # Find all records of the number
          possible_contacts = Contact.where(cell_phone: device_id)

          # If there are possible contacts then we need to find the last blast that was actually sent to them to provide a response.
          if possible_contacts.empty?
            #Respond With Message That We Could Not Find Record Of Them
            @mgageService.system_message(SystemValue.find_by_key("no_keyword_or_contact_response").value, nil, device_id, inbound_number)
          else

            # Finding all relationships to blasts with the contacts
            blast_contact_relationships = BlastContactRelationship.where(contact_id: possible_contacts.ids).order("created_at DESC")

            # Check to see if any relationships exists already
            if blast_contact_relationships.empty?
              @mgageService.system_message(SystemValue.find_by_key("no_keyword_or_recent_blast_response").value, nil, device_id, inbound_number)
            else
              most_recent_blast = nil
              current_time = Time.now
              brc_contact = nil

              # Looking for the last blast that was sent to them last and not ones that are scheduled
              for bcr in blast_contact_relationships
                  if bcr.blast.send_date_time < current_time
                      most_recent_blast = bcr.blast
                      brc_contact = Contact.find_by_id(bcr.contact_id)
                      break
                  end
              end

              if most_recent_blast.nil?
                #Send Message That A Resent Blast Could Not Be Found
                @mgageService.system_message(SystemValue.find_by_key("no_keyword_or_recent_blast_response").value, nil, device_id, inbound_number)
              else
                  # Create A Response
                  org = most_recent_blast.organization
                  keyword = Keyword.find_by(organization_id: org.id, id: most_recent_blast.keyword_id)

                  record_response(device_id, (brc_contact.nil? ? brc_contact.id : 0), (keyword.nil? ? nil : keyword.name ), false, message_type, message, mgage_message_id, message_subid)

                  #Respond to cell phone with response about matching them to a previous keyword
                  @mgageService.system_message("We have sent your message to keyword #{most_recent_blast.keyword_name}. Please provide a keyword before your message to ensure accurate deliveries.", nil, device_id, inbound_number)
              end
            end
          end
        else # Keyword Was Found
          keyword = parsed_message_results["keyword"]

          # Is this the system reserved opt out keywords
          if is_keyword_opt_out?(keyword)
            process_opt_out(device_id, keyword, message_type, message, mgage_message_id, message_subid, inbound_number)
            return
          elsif is_keyword_help?(keyword)
            process_system_help(keyword, device_id, inbound_number, message_type, message, mgage_message_id, message_subid)
            return
          else
            keyword_organization = keyword.organization
            organization_contact = keyword_organization.contacts.find_by_cell_phone(device_id)
            new_contact_created = false

            # Create them as a contact if they do not exist
            if !organization_contact
              organization_contact = Contact.create(cell_phone: device_id, organization_id: keyword_organization.id, active: true)

              if !organization_contact.save
                @mgageService.system_message(SystemValue.find_by_key("failed_to_opt_in_keyword").value, nil, device_id, inbound_number)
                return # Return since we cannot add the user to the system
              end

              new_contact_created = true
            end

            # Determine If The Message Contains Stop/Help Verbage
            message_array = parsed_message_results["message_array"]
            if message_array
              if message_array.length > 0

                # Opt Out Process
                if is_message_an_opt_out?(message_array)
                  process_opt_out(device_id, keyword, message_type, message, mgage_message_id, message_subid, inbound_number)
                  # Record The Response
                  record_response(device_id, organization_contact.id, keyword.name, false, message_type, message, mgage_message_id, message_subid)
                  return
                end

                # Help Process
                if is_message_a_help?(message_array)
                  process_system_help(keyword, device_id, inbound_number, message_type, message, mgage_message_id, message_subid)
                  # Record The Response
                  record_response(device_id, organization_contact.id, keyword.name, false, message_type, message, mgage_message_id, message_subid)
                  return
                end
              end
            end

            # Determine If The Organization Is Still Active
            if !keyword_organization.active
              # Record The Response
              record_response(device_id, organization_contact.id, keyword.name, false, message_type, message, mgage_message_id, message_subid)
              @mgageService.system_message("The organization that owns the keyword #{keyword.name} is no longer active.", nil, device_id, inbound_number)
              return
            end


             # Does the org user's phone # match the device_id's?
            if keyword_organization.users.pluck(:cell_phone).include?(device_id)
              # Process The Blast
              # Determine if mgage has duplicated the message
              existing_response = Response.where("message_id = ? ", mgage_message_id)

              if !existing_response.empty?
                return
              end

              if parsed_message_results["message_array"].empty?
                @mgageService.system_message("As a keyword admin, please provide a message after your keyword to send.", nil, device_id, inbound_number)
                return
              end

              # Start Processing The Admin Blast
              ApplicationRecord.transaction do

                filtered_message = MessageService.new(parsed_message_results["message_text"], keyword.name)

                # Determine Contacts
                contact_array = Array.new
                if !keyword.groups.empty?
                    for group in keyword.groups
                        contact_array += group.get_all_contacts_ids
                    end
                else
                    contact_array += keyword.organization.contacts.where(active: true).pluck("id")
                end

                # Determine if usage is alloted? (Rate & Credits)
                sms_rate = filtered_message.sms_rate
                usage = keyword_organization.current_credit_usage
                plan = keyword_organization.plan
                total_est = usage + (contact_array.count * sms_rate)
                cost = (contact_array.count * sms_rate)

                stripe_id = nil
                if plan.name == "Pay As You Go"
                  puts "-------> PAYGO"
                  # Returns a hash: [ Success: (true/false), error_message: (String), stripe_id: (String)]
                  cost = (sms_rate * 0.05 * contact_array.count ) > 0.50 ? (sms_rate * 0.05 * contact_array.count ) : 0.50
                  payment_processed = immediate_charge(cost, "Keyword Admin Message Blast", keyword_organization)
                  if !payment_processed["success"]
                    puts "FAILED PAYMENT :----> #{payment_processed['error_message']}"
                    ##TODO: Alert Account Owners About This Issue

                    #Text Failed Message To User
                    @mgageService.system_message("Your payment failed to send this blast. Please update your payment details in your account.", nil, device_id, inbound_number)
                    raise ActiveRecord::Rollback
                    return
                  end
                else
                  puts "-------> OTHER"
                  if total_est > plan.messages_included
                    @mgageService.system_message("You do not have enough credits to send this blast. Please upgrade your account.", nil, device_id, inbound_number)
                    raise ActiveRecord::Rollback
                    return
                  end
                end



                # Create The Blast
                new_blast = Blast.new(active: true, keyword_id: keyword.id, keyword_name: keyword.name, message: filtered_message.message, send_date_time: DateTime.now, sms: true, user_id: 0, organization_id: keyword_organization.id, rate: sms_rate, cost: cost, contact_count: contact_array.count, stripe_id: stripe_id)

                if !new_blast.save
                    #Raise Honey Badger Error
                    Honeybadger.notify("Failed to create an admin blast for a keyword admin that replied with a keyword and a message.", class_name: "Mgage Controller -> MO", error_message: new_blast.errors.full_messages)

                    #Text Failed Message To Admin
                    @mgageService.system_message(SystemValue.find_by_key("failed_keyword_admin_blast_create").value, nil, device_id, inbound_number)
                    raise ActiveRecord::Rollback
                    return
                end

                #--> Contacts <--#
                for contact in contact_array
                    contact_relationship = BlastContactRelationship.new(blast: new_blast, status: "Sent", contact_id: contact)
                    contact_relationship.save
                end



                # Send The Message
                @mgageService.process_message(keyword_organization, new_blast)

                # Response with success message
                @mgageService.system_message(SystemValue.find_by_key("successful_keyword_admin_blast_create").value, nil, device_id, inbound_number)

                # Record The Response
                record_response(device_id, organization_contact.id, keyword.name, false, message_type, message, mgage_message_id, message_subid)
              end
            else
              # Process Opt Ins
              if new_contact_created || parsed_message_results["message_array"].empty?

                result = process_opt_in(keyword, organization_contact)

                # Where the records created?
                if !result
                  # Record The Response
                  record_response(device_id, organization_contact.id, keyword.name, false, message_type, message, mgage_message_id, message_subid)

                  @mgageService.system_message(SystemValue.find_by_key("failed_to_opt_in_keyword").value, nil, device_id, inbound_number)
                  return
                end

                default_opt_in_message_obj = SystemValue.find_by_key("default_opt_in_text")
                additional_opt_out_text = SystemValue.find_by_key("additional_opt_out_text")
                opt_in_text = ""

                # Is a Survey Attached to the keyword
                keyword_surveys = keyword.surveys
                if !keyword_surveys.empty?
                  for survey in keyword_surveys
                    if survey.start_date_time <= DateTime.now && survey.end_date_time >= DateTime.now

                      new_url ="https://#{Rails.application.routes.default_url_options[:host]}/survey/#{survey.id}/#{organization_contact.id}/show"

                      if opt_in_text.blank?
                        opt_in_text = "#{survey.start_message} #{new_url}"
                      else
                        opt_in_text += " #{survey.start_message} #{new_url}"
                      end

                    end
                  end
                else
                  if keyword.opt_in_text
                    opt_in_text = keyword.opt_in_text
                  end
                end

                # Append Neccessary Messaages
                if opt_in_text.blank?
                    opt_in_text = "#{default_opt_in_message_obj.value}"
                else
                    opt_in_text += " #{additional_opt_out_text.value}"
                end

                # Handle Opt In Media (If it Exists)
                sms = true
                opt_in_media_url = nil
                if !keyword.opt_in_media.nil? && !keyword.opt_in_media.blank?
                    opt_in_media_url = keyword.opt_in_media.url
                    sms = false
                end

                filtered_message = MessageService.new(opt_in_text, keyword.name)

                # Determine Rate Of Message
                rate = 1
                if opt_in_media_url
                  rate = 3
                else
                  rate = filtered_message.sms_rate
                end

                ApplicationRecord.transaction do

                  new_blast = Blast.new(active: true, contact_count: 1, rate: rate, keyword_id: keyword.id, keyword_name: keyword.name, message: filtered_message.message, send_date_time: DateTime.now, user_id: 0, cost: rate, sms: sms, organization_id: keyword_organization.id)

                  if !new_blast.save
                    #Raise Honey Badger Error
                    Honeybadger.notify("Failed to create a blast for opt-in.", class_name: "Mgage Controller -> MO", error_message: new_blast.errors.full_messages)

                    #Text Failed Message To User
                    @mgageService.system_message(SystemValue.find_by_key("failed_to_opt_in_keyword").value, nil, device_id, inbound_number)
                    raise ActiveRecord::Rollback
                  end

                  if sms == false
                    new_blast_attachment = BlastAttachment.create(blast_id: new_blast.id, attachment: keyword.opt_in_media)
                    new_blast_attachment.save
                  end

                  blast_contact_relationships = BlastContactRelationship.new(contact_id: organization_contact.id, contact_number: organization_contact.cell_phone, blast_id: new_blast.id, status: "Sent")

                  if !blast_contact_relationships.save
                    #Raise Honey Badger Error
                    Honeybadger.notify("Failed to create a blast and contact relationship.", class_name: "Mgage Controller -> MO", error_message: blast_contact_relationships.errors.full_messages)

                    #Text Failed Message To User
                    @mgageService.system_message(SystemValue.find_by_key("failed_to_opt_in_keyword").value, nil, device_id, inbound_number)
                    raise ActiveRecord::Rollback
                  end

                  # Pay Go Handling + Credit Checks

                  #   # Returns a hash: [ Success: (true/false), error_message: (String), stripe_id: (String)]
                  #   dollar_cost = (rate * 0.05) > 0.50 ? (rate * 0.05) : 0.50
                  #   payment_processed = immediate_charge(dollar_cost, "Opt In Message Blast", keyword_organization)
                  #   if !payment_processed["success"]
                  #     puts "FAILED PAYMENT :----> #{payment_processed['error_message']}"
                  #     ##TODO: Alert Account Owners About This Issue

                  #     #Text Failed Message To User
                  #     @mgageService.system_message(SystemValue.find_by_key("failed_to_opt_in_keyword").value, nil, device_id, inbound_number)
                  #     raise ActiveRecord::Rollback
                  #   end

                  #   new_blast.update(stripe_id: payment_processed["stripe_id"], rate: dollar_cost)
                  # else
                  # if keyword_organization.credits_left <= 50
                  #   for user in keyword_organization.users
                  #     incoming_num = OrganizationPhoneRelationship.where(mass_outgoing: true, organization_id: keyword_organization).first.phone_number
                  #     @mgageService.system_message("Your account is running low on credits.", nil, "1#{user.cell_phone}", incoming_num.real)
                  #   end
                  # end

                  # for user in organization.users
                  #     mgage_service = MgageMasterService.new()
                  #     incoming_num = OrganizationPhoneRelationship.where(mass_outgoing: true, organization_id: organization).first.phone_number
                  #     mgage_service.system_message("Your account is running low on credits.", nil, "1#{user.cell_phone}", incoming_num.real)
                  # end

                    usage = keyword_organization.current_credit_usage
                    plan = keyword_organization.plan
                    total_est = usage + (1 * filtered_message.sms_rate)

                  # if total_est > plan.messages_included
                  #   ##TODO: Alert Account Owners About This Issue
                  #
                  #   #Text Failed Message To User
                  #   @mgageService.system_message(SystemValue.find_by_key("failed_to_opt_in_keyword").value, nil, device_id, inbound_number)
                  #   raise ActiveRecord::Rollback
                  # end

                  if carrier == "mgage"
                    @mgageService.process_message(keyword_organization, new_blast)
                  else
                    @bandwidth.process_blast(new_blast)
                  end

                end

                # Record The Response
                record_response(device_id, organization_contact.id, keyword.name, false, message_type, message, mgage_message_id, message_subid)

                return
              else
                # Response Only
                # Record The Response
                record_response(device_id, organization_contact.id, keyword.name, false, message_type, message, mgage_message_id, message_subid)

                @mgageService.system_message(SystemValue.find_by_key("logged_response_to_account").value, nil, device_id, inbound_number)
                return
              end
            end
          end
        end
      end
      #----> NEW <----#
    end

    private

    # Determines if the keyword is a reserved opt out keyword
    def is_keyword_opt_out?(keyword)
      return ["stop", "quit", "end", "unsubscribe"].include?(keyword.name)
    end

    # Determines if the keyword is a reserved help keyword
    def is_keyword_help?(keyword)
      return ["help"].include?(keyword.name)
    end

    # Processes the opt out of a contact
    def process_opt_out(device_id, keyword, message_type, message, mgage_message_id, message_subid, inbound_number)
      found_contacts = Contact.where(cell_phone: device_id) # Find all instances of the contact
      all_accounts_marked_inactive = true
      for c in found_contacts # Iterate over all instances and make the contact inactive.
        if c.organization
          if !c.update(active: false)
            #Raise HoneyBadger Issue
            Honeybadger.notify("Failed to make contact inactive due to opt out without a keyword. #{ c.errors.full_messages}", class_name: "Mgage Controller -> MO", error_message: c.errors.full_messages)
            all_accounts_marked_inactive = false
          else
            record_response(device_id, c ? c.id : 0, keyword ? keyword.name : nil, true, message_type, message, mgage_message_id, message_subid)
          end
        end
      end

      if all_accounts_marked_inactive
          #Send Opt Out Message To Contact
          @mgageService.send_opt_out_message(device_id, inbound_number)
      else
          #Send Failed To Opt Out, Please Contact
          @mgageService.system_message(SystemValue.find_by_key("failed_to_opt_out_all_accounts").value, nil, device_id, inbound_number)
      end
    end

    # Processes the help keyword response
    def process_system_help(keyword, device_id, inbound_number, message_type, message, mgage_message_id, message_subid)
      contact = Contact.find_by(cell_phone: device_id, organization: keyword.organization)
      help_msg = generate_help_message(keyword)
      msg_rate = ApplicationController.helpers.sms_rate_check(help_msg)
      help_blast = Blast.new(
        user_id: -2,
        organization: keyword.organization,
        active: true,
        keyword_id: keyword.id,
        keyword_name: keyword.name,
        message: help_msg,
        sms: true,
        send_date_time: Time.now,
        contact_count: 1,
        cost: msg_rate,
        rate: msg_rate
      )
      if !help_blast.save
        Honeybadger.notify("Failed to save help system message to blast | keyword: #{keyword.id}", class_name: "Mgage Controller -> MO", error_message: help_blast.errors.full_messages)
      else
        if contact
          blast_contact_relationship = BlastContactRelationship.new(blast: help_blast, status: "Sent", contact_id: contact.id)

          if !blast_contact_relationship.save
            HoneyBadger.notify("Error sending survey completion confirmation text | blast: #{help_blast.id}, contact: #{contact.id}")
          end
        end
      end

      @mgageService.system_message(help_msg, nil, device_id, inbound_number)
      record_response(device_id, 0, keyword.name, false, message_type, message, mgage_message_id, message_subid)
      return
    end

    # Processes Opt In Of A Contact
    def process_opt_in(keyword, contact)
      logger.info("Adding user to this keyword")
      # Reactivate Contact For Opting Back In
      if !contact.active
        if !contact.update(active: true)
          Honeybadger.notify("Failed to update contact as active.", class_name: "Mgage Controller -> MO", error_message: contact.errors.full_messages)
          return false
        end
      end

      # Add The Contact To The Keyword Groups
      for group in keyword.groups
        already_existing_contact_group_relation = GroupContactRelationship.find_by(contact_id: contact.id, group_id: group.id)
        if !already_existing_contact_group_relation
          contact_group_rel = GroupContactRelationship.create(contact_id: contact.id, group_id: group.id)
          if !contact_group_rel
            #RAISE HoneyBadger Issue
            Honeybadger.notify("Failed to add a contact to a keyword group.", class_name: "Mgage Controller -> MO", error_message: contact_group_rel.errors.full_messages)
            return false
          end
        end
      end

      return true
    end


    def generate_help_message(keyword)
      #Send Help Message
      if keyword
        if keyword.name != "help"
          if keyword.help_text
            return "#{keyword.name.upcase} #{keyword.help_text} #{SystemValue.find_by_key("default_help_text").value} #{keyword.organization.users.first.email}"
          else
            return "#{keyword.name.upcase} #{SystemValue.find_by_key("default_help_text").value} #{keyword.organization.users.first.email}"
          end
        else
          return "#{keyword.name.upcase} #{keyword.help_text}"
        end
      else
        return SystemValue.find_by_key("default_help_text").value
      end
    end

    # Records A Response Message
    def record_response(cell_phone, contact_id, keyword_name, opt_out, message_type, message, mgage_message_id, message_subid)
      possible_opt_out = false
      if message
        downcase_message = message.downcase
        if downcase_message.match(/stop/) || downcase_message.match(/end/) || downcase_message.match(/quit/) || downcase_message.match(/cancel/) || downcase_message.match(/unsubscribe/)
          possible_opt_out = true
        end
      end
      new_response = Response.new(cell_phone: cell_phone, contact_id: contact_id, keyword: keyword_name, opt_out: opt_out, message_type: message_type, message: message, message_id: mgage_message_id, sub_id: message_subid, possible_opt_out: possible_opt_out)

      if !new_response.save
        logger.info(new_response.errors.full_messages)
        #Raise HoneyBadger Error
        Honeybadger.notify("Failed to create a response for a contact that replied with no keyword.", class_name: "Mgage Controller -> MO", error_message: new_response.errors.full_messages)
      end
      return
    end

    # Parses the message and keyword.
    # Returns a Hash [Keyword:String MessageArray: Array MessageText: String]
    def parse(message)
      response_hash = Hash.new
      message = message.gsub("\u0000", '') # Handling Null bytes
      message_array = message.split(" ") # Removing spaces from the message
      if message_array.empty? # Check to see if the message was just blank spaces
        return nil
      else
        keyword_result = Keyword.find_by_name(message_array[0].downcase)
        if keyword_result
          message_array.shift()
          response_hash["keyword"] = keyword_result
          response_hash["message_array"] = message_array
          response_hash["message_text"] = message_array.join(" ")
        else
          response_hash["keyword"] = nil
          response_hash["message_array"] = message_array
          response_hash["message_text"] = message_array.join(" ")
        end
      end
      return response_hash
    end

    # Determines if they body of the message (Not the Keyword) is trying to opt out
    def is_message_an_opt_out?(message_array)

      # Check the first word
      possible_stop_word = message_array[0]
      if possible_stop_word
        possible_stop_word = possible_stop_word.downcase
        if possible_stop_word == "stop" || possible_stop_word == "quit" || possible_stop_word == "end" || possible_stop_word == "cancel" || possible_stop_word == "unsubscribe"
          return true
        end
      end

      #Check the second word
      other_possible_stop_word = message_array[1]
      if other_possible_stop_word
        other_possible_stop_word = other_possible_stop_word.downcase
        if other_possible_stop_word == "stop" || other_possible_stop_word == "quit" || other_possible_stop_word == "end" || other_possible_stop_word == "cancel" || other_possible_stop_word == "unsubscribe"
          return true
        end
      end

      return false
    end

    # Determines if they body of the message (Not the Keyword) is trying to request for help
    def is_message_a_help?(message_array)

      possible_help_word = message_array[0]
      if possible_help_word
        possible_help_word = possible_help_word.downcase
        if possible_help_word == "help"
          return true
        end
      end

      other_possible_help_word = message_array[1]
      if other_possible_help_word
        other_possible_help_word = other_possible_help_word.downcase
        if other_possible_help_word == "help"
          return true
        end
      end

      return false
    end

end
