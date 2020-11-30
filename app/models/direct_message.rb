class DirectMessage < ApplicationRecord

    # Relationships
    belongs_to :organization_contact_relationship
    # has_many :direct_message_medias

    # Validations
    validates :message, presence: true
    validates :to, presence: true
    validates :from, presence: true
    validates :message_id, presence: true

end
