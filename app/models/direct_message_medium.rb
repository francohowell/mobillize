class DirectMessageMedium < ApplicationRecord

    # Relationships
    belongs_to :direct_message

    # Validations 
    validates :media_number, presence: true
    validates :media_url, presence: true 
    

end
