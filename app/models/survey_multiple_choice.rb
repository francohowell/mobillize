class SurveyMultipleChoice < ApplicationRecord

    # Relationships 
    belongs_to :survey_question
    
    # Validations
    validates :choice_item, presence: true, length: { minimum: 1 }
    validates :survey_question_id, presence: true

    # Methods 

end
