class BlastContactRelationship < ApplicationRecord

    # Relationships 
    belongs_to :blast
    
    # Validations
    validates :contact_id, presence: true
    validates :contact_number, presence: true 
    validates :status, presence: true

end
