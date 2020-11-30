class TwilioController < ApplicationController
    skip_before_action :verify_authenticity_token
    skip_before_action :notification_check
    skip_before_action :active_billing_status
    protect_from_forgery with: :null_session

    layout 'empty'

    def twilio_response
        head :ok

        long_code = params[:To]
        standard_long_code = long_code.gsub("+","")
        sender_phone = params[:From]
        sender_phone = sender_phone.gsub("+","")
        message_id = params[:MessageSid]
        media_count = params[:NumMedia]
        message_text = params[:Body]
        media_array = []
        media_count = media_count.to_i
        i = 0
        while i < media_count
            media_array.push(params["MediaUrl#{i}"])
            i += 1
        end

        logger.info("Parsing Incoming Twilio Message: SENDER #{sender_phone}, LNGCD #{long_code}")
    end

end
