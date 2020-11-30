class SurveyResponseQueueRelationship < ApplicationRecord
  # Relationships
  belongs_to :survey_response
  belongs_to :custom_queue

  # Methods
  
  def contact
    Contact.find_by_id(self.survey_response.contact_id)
  end
  
  def survey
    self.survey_response.survey
  end
end
