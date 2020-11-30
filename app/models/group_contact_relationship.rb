class GroupContactRelationship < ApplicationRecord

    # Relationships 
    belongs_to :group
    belongs_to :contact
end
