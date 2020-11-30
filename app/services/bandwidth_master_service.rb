require 'bandwidth'

class BandwidthMasterService

    include Bandwidth
    include Bandwidth::Voice
    include Bandwidth::Messaging

    attr_reader :client
    attr_reader :iris_client
    attr_reader :account_id 
    attr_reader :application_id
    
    def initialize()
        
        @client = Bandwidth::Client.new(
            voice_basic_auth_user_name: Rails.application.credentials.bandwidth_username,
            voice_basic_auth_password:  Rails.application.credentials.bandwidth_password,
            messaging_basic_auth_user_name: Rails.application.credentials.bandwidth_api_token,
            messaging_basic_auth_password:  Rails.application.credentials.bandwidth_api_secret,
        )

        @iris_client = BandwidthIris::Client.new(  Rails.application.credentials.bandwidth_account_id,  Rails.application.credentials.bandwidth_username,  Rails.application.credentials.bandwidth_password )

        @account_id = Rails.application.credentials.bandwidth_account_id
        @application_id = Rails.application.credentials.bandwidth_application_id

    end

    def process_blast(blast)

        messaging_client = @client.messaging_client.client
        for bcr in blast.blast_contact_relationships

            body = MessageRequest.new
            body.application_id = @application_id
            body.to = "+#{bcr.contact_number}"
            body.from = "+18664743663"
            body.text = "#{blast.keyword_name.upcase} #{blast.message}"

            begin
                response = messaging_client.create_message(@account_id, :body => body)
                # return {success: true, status_code: response.status_code, message_id: response.data.id, segments: response.data.segment_count}
            rescue Exception => e
                logger.error("Blast error: #{e}")
            end
        end

    end

    def send_message(to, from, message)

        messaging_client = @client.messaging_client.client

        body = MessageRequest.new
        body.application_id = @application_id
        body.to = to
        body.from = from
        body.text = message

        begin
            response = messaging_client.create_message(@account_id, :body => body)
            return {success: true, status_code: response.status_code, message_id: response.data.id, segments: response.data.segment_count}
        rescue Exception => e
            return {success: false, error: e}
        end

    end

    def search_for_toll_free_number(word)
        # Check To See If Word Is <= 7 in lenght
        if !word
            Honeybadger.notify("No Query Item Was Provided.", class_name: "Bandwidth Master Service -> Search For Toll Free Number")
            return {success: false, error_message: "A search query must be provided."} 
        end
        if word.length > 7            
            return {success: false, error_message: "A search query must be provided that is less than 7 characters long."}  
        end
        begin
            results = BandwidthIris::AvailableNumber.list({toll_free_vanity: word, :quantity =>1})
            return {success: true, phone_number: results[0]}  
        rescue Exception => e
            return {success: false, error_message: e}
        end
    end

    def random_toll_free_number 
        begin
            results = BandwidthIris::AvailableNumber.list(@iris_client, {toll_free_wild_card_pattern: "8**", :quantity =>1})            
            return {success: true, phone_number: results[0]}  
        rescue Exception => e
            return {success: false, error_message: e}
        end
    end

    def allocate_random_toll_free_number(user_id, parent_organization_id)

        user = User.find_by_id(user_id)
        if !user.sources.where(child_organization_id: nil, parent_organization_id: parent_organization_id).empty?
        organization = ParentOrganization.find_by_id(parent_organization_id)

            begin
        
                phone_numbers = BandwidthIris::AvailableNumber.list(@iris_client, {toll_free_wild_card_pattern: "8**", :quantity =>1})
                puts "------> PHONE NUMBERS: #{phone_numbers}"
                order_data = {
                    :name => "Mobilize Comms Order",
                    :site_id => 39312, # Sub Account Id
                    :existing_telephone_number_order_type => {
                        :telephone_number_list => {
                            :telephone_number => [phone_numbers[0]]
                        }
                    }
                }

                order_response = BandwidthIris::Order.create(@iris_client, order_data)

                new_phone_order = PhoneNumberOrder.new(aggregator_order_id: order_response.id, aggregator_order_last_update: Time.now, aggregator_order_status: "PENDING", parent_organization_id: parent_organization_id, phone_number: "+1#{phone_numbers[0]}", user_id: user_id)

                if !new_phone_order.save 
                    Appsignal.set_error("Failed to create a new phone order record. #{new_phone_order.errors.full_messages}")
                    return {success: false, error_message: new_phone_order.errors.full_messages}
                end

                return {success: true}


            rescue Exception => e
                return {success: false, error_message: e}
            end
        else
            return {success: false, error_message: "You are not a user of this organization."}
        end


    end

    

end

