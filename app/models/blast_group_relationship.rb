class BlastGroupRelationship < ApplicationRecord
    
    #Relationships 
    belongs_to :blast
    belongs_to :group  
end
