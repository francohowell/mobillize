module ContactsHelper
    include Pagy::Frontend

    def strip_number(phone_number)
        stripped_number = phone_number.delete('^0-9') #Remove all characters except 
        if stripped_number.length == 10
            stripped_number = "1" + stripped_number
        end 
        return stripped_number
    end
    
end
