class KeywordSurveyRelationship < ApplicationRecord

  # Relationships 
  belongs_to :survey
  belongs_to :keyword
  
end
