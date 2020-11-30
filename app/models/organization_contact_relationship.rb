class OrganizationContactRelationship < ApplicationRecord

    # Relationships 
    belongs_to :organization
    belongs_to :contact 
    has_many :direct_messages

end
