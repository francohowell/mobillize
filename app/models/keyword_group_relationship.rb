class KeywordGroupRelationship < ApplicationRecord
    
    # Relationships 
    belongs_to :keyword
    belongs_to :group

end
