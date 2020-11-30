class SurveyAnswer < ApplicationRecord

    # Relationships 
    belongs_to :survey_response
    belongs_to :survey_question

    # Validations
    validates :answer, length: { minimum: 1 }, allow_blank: true
    validates :survey_response_id, presence: true
    validates :survey_question_id, presence: true

    # Methods 

end
