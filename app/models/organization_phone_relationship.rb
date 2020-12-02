class OrganizationPhoneRelationship < ApplicationRecord
   
    # Relationships 
    belongs_to :organization
    belongs_to :phone_number

end
