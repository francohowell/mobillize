require 'csv'

class Group < ApplicationRecord

    # Relations 
    belongs_to :organization
    has_many :group_contact_relationships,  dependent: :destroy
    has_many :contacts, through: :group_contact_relationships
    has_many :keyword_group_relationships,  dependent: :destroy
    has_many :keywords, through: :keyword_group_relationships
    has_many :blast_group_relationships, dependent: :destroy
    has_many :blasts, through: :blast_group_relationships

    # Validations 
    validates :name, presence: true, length: { minimum: 2 }
    
    # Methods
    def get_user 
        User.find_by_id(self.user_id)
    end

    def get_all_contacts 
        return self.contacts.where(active: true)
    end

    def get_all_contacts_ids
        return self.contacts.where(active: true).pluck(:id)
    end

    def get_contact_count
        return  self.contacts.where(active: true).count
    end

    def reset 
        # Contacts 
        if !self.group_contact_relationships.empty?
            self.group_contact_relationships.destroy_all
        end


        if self.group_contact_relationships.empty?
            return true
        else
            return false
        end
    end

    def contacts_data
        attributes = %w{cell_phone first_name last_name primary_email secondary_email company_name}

        CSV.generate(headers: true) do |csv|
            csv << attributes

            self.contacts.each do |c|
                csv << attributes.map{ |attr| c.send(attr) }
            end
        end
    end

    def contacts_destroy
        for c in self.contacts
            c.destroy
        end
    end
    
end
