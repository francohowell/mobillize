class PhoneNumber < ApplicationRecord

    # Relationships 
    has_many :organization_phone_relationships
    has_many :organizations, through: :organization_phone_relationships

    # Validations
    validates :pretty, presence: true, length: { minimum: 5 }
    validates :real, presence: true, length: { minimum: 5 }
    validates :service_id, presence: true

end
