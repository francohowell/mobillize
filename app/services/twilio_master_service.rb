class TwilioMasterService
    attr_reader :client

    def initialize()
        @client = Twilio::REST::Client.new()
    end

    def find_us_number
        begin
            return [@client.api.available_phone_numbers('US').local.list(sms_enabled: true, mms_enabled: true, exclude_all_address_required: true).first, { success: true}]
        rescue Twilio::REST::TwilioError => e
            return [nil, {failed: e}]
        rescue => exception
            return [nil, {failed: exception}]
        end
    end

    def find_local_number(state)
        begin
            return [@client.api.available_phone_numbers('US').local.list(sms_enabled: true, mms_enabled: true, exclude_all_address_required: true, in_region: state).first, {success: true}]
        rescue Twilio::REST::TwilioError => e
            return [nil, {failed: e}]
        rescue => exception
            return [nil, {failed: exception}]
        end
    end

    def send_direct_message(from, to, content)
        begin
            message = @client.messages.create(
                from: from,
                to: to,
                body: content
            )
            return [message, {success: true}]
        rescue Twilio::REST::TwilioError => e
            return [nil, {failed: e}]
        rescue => exception
            return [nil, {failed: exception}]
        end
    end

    def delete_existing_long_code
    end

    def purchase_number(twilio_number)
        begin
            new_number = @client.incoming_phone_numbers.create(phone_number: twilio_number, sms_url: "https://#{Rails.application.routes.default_url_options[:host] == "localhost:3000" ? "messaging.mobilizecomms.com" : Rails.application.routes.default_url_options[:host]}/twilio_response")
        rescue Twilio::REST::TwilioError => e
            return [nil, { failed: e }]
        end
        data, status = create_phone_number_record(new_number)
        if status[:failed].present?
            return [nil, { failed: data} ]
        else
            return [data, {success: true} ]
        end
    end

    def release_number(twilio_number_id)
        begin
           @client.incoming_phone_numbers(twilio_number_id).delete
            return {success: true, response: nil}
        rescue Twilio::REST::TwilioError => e
            return {success: false, response: e}
        rescue => exception
            return {success: false, response: e}
        end
    end

    def lookup_contact(cell_phone)
      phone_number = @client.lookups
                          .phone_numbers('+' + cell_phone)
                          .fetch(type: ['caller-name', 'carrier'])

      return phone_number
    end

    private

    def create_phone_number_record(new_number)
        p = PhoneNumber.new(demo: false, global: false, pretty: new_number.friendly_name, real: new_number.phone_number, service_id: new_number.sid, long_code: true)
        if !p.save
            return [p.errors.full_messages, {failed: exception }]
        else
            return [p, {success: true }]
        end
    end


end
