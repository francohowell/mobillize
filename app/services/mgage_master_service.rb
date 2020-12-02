require 'logger'

class MgageMasterService
    attr_reader :username
    attr_reader :password 
    attr_reader :base_url

    include HTTParty
    
    def initialize()
        @username = Rails.application.credentials.mgage_username
        @password =  Rails.application.credentials.mgage_password
        @base_url = "https://directtext.mgage.com/a2w_preRouter/httpApiRouter"
    end

    def system_message(message, media_url, cell_phone, incoming_number)

        message = message_filter(message)

        if !media_url
            data = send_mt(incoming_number, message, cell_phone, "sms", nil)
        else
            data = send_mt(incoming_number, message, cell_phone, "multimedia", media_url)
        end
        if !data
            Honeybadger.notify("Failed to send API call to mGAGE. message: #{message} contact: #{cell_phone}", class_name: "Mgage Master Service -> System Message")
        end
    end

    def process_message(organization, blast)
        

        blast_contacts = []
        blast_array = []

        for blast_contact_id in blast.contact_ids 
            current_contact = Contact.find_by_id(blast_contact_id)
            if current_contact
                blast_contacts.push(current_contact.cell_phone)
            end
        end

        blast_array = blast_contacts.each_slice(90).to_a

        blast_array.each_with_index do |b, index|

            puts "Blast Contact Segment #{index}"
            puts "Blast Contact Cell Phones: #{b}"

            outgoing_message = message_filter(blast.outgoing_message)
            
            if blast.sms 
                data = send_mt(organization.organization_phone_relationships.where(mass_outgoing: true).first.phone_number.real, outgoing_message, b.join(","), "sms", nil)
                puts "Blast Data: #{data}"
            else
                data = send_mt(organization.organization_phone_relationships.where(mass_outgoing: true).first.phone_number.real, outgoing_message, b.join(","), "multimedia", blast.blast_attachments.empty? ? nil : blast.blast_attachments.first.attachment.url)
            end

            #logger.debug("------> DATA: #{data}")

            if data
                code = read_value('httpApiResponse.code', data)
                if code == "100"
                    recipients = read_value('httpApiResponse.recipients.recipient', data)
                    if recipients
                        rcps = recipients.is_a?(Array) ? recipients : [recipients]
                        for recipient in rcps
                            update_blast_contact_relationship_message_id(recipient["mobileNumber"], recipient["messageId"], blast) 
                        end
                    end
                end
            end
        end
    end

    # is this not part of the recurring blast message? 
    def send_opt_out_message(contact_id, code_opt_out)
        
        message = message_filter(SystemValue.find_by_key("default_opt_out_text").value)
        data = send_mt(code_opt_out, message, contact_id, "sms", nil)

        if !data
            Honeybadger.notify("Failed to send API call to mGAGE. contact: #{contact_id}", class_name: "Mgage Master Service -> Send Opt Out Message")
        end
    end

    def send_opt_in_message(contact_id, code_opt_in, keyword_id)
        

        keyword = Keyword.find_by_id(keyword_id)
        default_opt_in_message_obj = SystemValue.find_by_key("default_opt_in_text")
        additional_opt_out_text = SystemValue.find_by_key("additional_opt_out_text")
        if keyword
            opt_in_text = nil
            if keyword.opt_in_text 
                opt_in_text = "#{keyword.name.upcase} #{keyword.opt_in_text}"
            end
            if opt_in_text.nil? || opt_in_text.empty?
                opt_in_text = "#{keyword.name} #{default_opt_in_message_obj.value}"
            else
                opt_in_text += additional_opt_out_text.value
            end
        else
            opt_in_text = "#{keyword.name} #{default_opt_in_message_obj.value}"
        end

        message = message_filter(opt_in_text)
        data = send_mt(code_opt_in, message, contact_id, "sms", nil)

        if !data
            Honeybadger.notify("Failed to send API call to mGAGE. keyword: #{keyword_id} contact: #{contact_id}", class_name: "Mgage Master Service -> Send OPT In Message")
        end
    end

    def send_help_message(contact_id, code_opt_in, keyword_id)
        

        keyword = Keyword.find_by_id(keyword_id)
        structured_help_text = "#{keyword.name.upcase} Please contact #{keyword.organization.users.first.email}. Reply STOP to cancel, HELP for help. Msg and Data Rates May Apply."
    
        message = message_filter(structured_help_text)
        data = send_mt(code_opt_in, message, contact_id, "sms", nil)

        if !data
            Honeybadger.notify("Failed to send API call to mGAGE. contact: #{contact_id}", class_name: "Mgage Master Service -> Send Help Message")
        end
    end

    def send_admin_failure_message(contact_id, code_opt_in, keyword_id, additional_message)
        

        keyword = Keyword.find_by_id(keyword_id)

        message = "Your message failed to be sent out your keyword contacts."
        if additional_message
            message = message + " #{additional_message}"
        end


        message = message_filter(message)
        data = send_mt(code_opt_in, message, contact_id, "sms", nil)
        
        if !data
            Honeybadger.notify("Failed to send API call to mGAGE. contact: #{contact_id}", class_name: "Mgage Master Service -> Send Admin Failure Message")
        end
    end


    private

    def message_filter(message)
        message = message.gsub("\u00A0", " ")
        return message
    end

    def send_mt(reply_to, body, recipient, channel, content_url)
        auth = {
            username: @username,
            password: @password
        }

        # Formatt The Responses
        body = CGI.escape(body)

        if content_url
            content_url = CGI.escape(content_url)
        end

        if channel == "multimedia"
            query =  {reply_to: reply_to, body: body, recipient: recipient, channel: channel, content_url: content_url} #content_url
        else
            query = {reply_to: reply_to, body: body, recipient: recipient}
        end

       
        response = HTTParty.post(@base_url, basic_auth: auth, query: query, debug_output: $stdout, query_string_normalizer: proc { |query|
            query.map do |key, value|
                "#{key}=#{value}"
            end.join('&')
        })
        puts "-----> RESPONSE: #{response}"
        if response
            return response.parsed_response
        else
            return nil
        end
    end

    def update_blast_contact_relationship_message_id(mobilenumber, messageid, blast)
        contact = blast.organization.contacts.find_by(cell_phone: mobilenumber)
        if contact
            bcr = BlastContactRelationship.find_by(blast_id: blast.id, contact_id: contact.id)
            if bcr
                bcr.message_id = messageid
                bcr.status = "Sent"
                if !bcr.save 
                    Honeybadger.notify("Failed to update a Blast Contact Relationship of blast: #{blast.id} contact: #{contact.id} | #{bcr.errors.full_messages}", class_name: "Mgage Master Service -> Process Message")
                end
            end
        end
    end

    def read_value(path, obj)
        parts = path.split('.')
        tree = obj
        for p in parts
            if tree.include?(p)
                tree = tree[p]
            else 
                return nil
            end
        end
        return tree
    end
    
    
end