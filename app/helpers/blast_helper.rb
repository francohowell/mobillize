module BlastHelper

    def logger
        Rails.logger
    end

    # Determines The Rate Of The Message 
    def sms_rate_check(message) 
        # credit_rate
        logger.info("SMS ENCODING: #{message}")
        sms_encoding = SmsTools::EncodingDetection.new message 
        logger.info("Encoding Detection: #{sms_encoding.encoding}")

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
  

    # Replaces Characters In A Message That May Cause Issues
    def filter_message(message)
        message.gsub!(/\u2019/, "\u0027") # Replace a right single quote with apostrophe 
        message.gsub!(/\u2018/, "\u0027") # Replace a left single quote with apostrophe 
        message.gsub!(/\u20A0/, "\u0020") # Replaces a No Break Space with a Space
        return message
    end


    def calculate_messages_to_be_used(group_ids, contact_ids)
        contact_array = []
        if group_ids # Get the groups count
            for g in group_ids
                gp = Group.find_by_id(g)
                contact_array += gp.get_all_contacts_ids
            end
        end

        if contact_ids # Get the groups count
            contact_array += contact_ids
        end

        contact_array = contact_array.uniq
        
        return contact_array.count
    end

    def set_blast_job(organization_id, current_blast, scheduled_date)
        if scheduled_date
            job_id = BlastJob.perform_at(Time.parse(scheduled_date.to_s), organization_id, current_blast.id)
        else
            job_id = BlastJob.perform_async(organization_id, current_blast.id)
        end
        current_blast.job_id = job_id
        if !current_blast.save
            return false 
        end
        return true
    end

end
