class Response < ApplicationRecord

    # Validates
    validates :cell_phone, presence: true 
    validates :message_id, presence: true 
    validates :message_type, presence: true 
    validates :message, presence: true 

    # Methods
    def self.to_csv
      attributes = ["cell_phone","contact_id", "name", "keyword","message"]
  
      CSV.generate(headers: true) do |csv|
        csv << attributes
  
        all.each do |response|
          csv << attributes.map{ |attr| response.send(attr) }
        end
      end
    end

    def name 
      found_keyword = Keyword.find_by_name(self.keyword)
      if found_keyword
        kwd_org = found_keyword.organization
        if kwd_org
          found_contact = kwd_org.contacts.find_by_cell_phone(self.cell_phone)
          if found_contact
            return "#{found_contact.first_name} #{found_contact.last_name}"
          end
        end
      end
    end

end
