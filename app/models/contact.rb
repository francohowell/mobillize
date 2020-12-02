class Contact < ApplicationRecord

    # Relationships
    belongs_to :organization 
    has_many :group_contact_relationships, dependent: :destroy
    has_many :groups, through: :group_contact_relationships
    has_many :organization_contact_relationships, dependent: :destroy

    # Validations
    validates :cell_phone, presence: true, phone: { possible: true }
    validates :user_id, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :cell_phone, uniqueness: { scope: :organization_id }
    validates :organization_id, uniqueness: { scope: :cell_phone }
    validates :primary_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
    validates :secondary_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
    validates :company_name, length: {minimum: 2}, allow_blank: true
    validate :is_contact_unique?, on: :create
    validates :first_name, allow_blank: true, length: { minimum: 2 }
    validates :last_name, allow_blank: true, length: { minimum: 2 }

    # Serializations
    serialize :dynamics, HashSerializer


    # Methods
    def is_contact_unique?
        stripped_number = strip_number(self.cell_phone)
        if Contact.where(organization_id: self.organization_id, cell_phone: stripped_number).count > 0
            errors.add(:contact, "already exists in your account.")
        end
    end

    def strip_number(phone_number)
        stripped_number = phone_number.delete('^0-9') #Remove all characters except 
        if stripped_number.length == 10
            stripped_number = "1" + stripped_number
        end 
        return stripped_number
    end

    before_create do
        self.cell_phone = strip_number(self.cell_phone)
    end

    before_save do 
        self.cell_phone = self.cell_phone.delete('^0-9') #Remove all characters except digits
        if self.first_name
            self.first_name = self.first_name.encode('utf-8')
        end
        if self.last_name
            self.last_name = self.last_name.encode('utf-8')
        end
    end

    after_create do
        OrganizationContactRelationship.create(organization_id: self.organization.id, contact_id: self.id)
    end

    def name 
        if first_name && last_name 
            return "#{first_name} #{last_name}"
        else
            return ""
        end
    end

    def self.to_csv
        attributes = %w{first_name last_name cell_phone primary_email secondary_email}

        CSV.generate(headers: true) do |csv|
            csv << attributes

            all.each do |contact|
                csv << attributes.map{ |attr| contact.send(attr) }
            end
        end
    end

    def blast_ids
        BlastContactRelationship.where(contact_id: self.id).blasts
    end

end
