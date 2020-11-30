require 'logger'

class MessageService
    attr_reader :message
    attr_reader :keyword_name
    attr_reader :blast_message

    def initialize(message, keyword_name)
        @message = message
        @keyword_name = keyword_name
        filter_message()
        if @keyword_name
            @blast_message = "#{@keyword_name} #{@message}"
        else
            @blast_message = @message
        end
    end

    def sms_rate 
        sms_encoding = SmsTools::EncodingDetection.new @blast_message 
        if SmsTools::GsmEncoding.valid? message  
            if message.length <= 160 
                return 1 
            else
                if sms_encoding.concatenated?
                    return sms_encoding.concatenated_parts
                else
                    return 1
                end
            end
        else 
            if message.length <= 70
                return 1
            else
                if sms_encoding.concatenated?
                    return sms_encoding.concatenated_parts
                else
                    return 1
                end
            end
        end
    end

    private 

    # Replaces Characters In A Message That May Cause Issues
    def filter_message()
        @message = @message.gsub(/\u2019/, "\u0027") # Replace a right single quote with apostrophe 
        @message = @message.gsub(/\u2018/, "\u0027") # Replace a left single quote with apostrophe 
        @message = @message.gsub(/\u20A0/, "\u0020") # Replaces a No Break Space with a Space
    end

end