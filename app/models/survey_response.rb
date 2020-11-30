class SurveyResponse < ApplicationRecord
  
  # Relationships 
  belongs_to :survey
  has_many :survey_answers, dependent: :destroy
  has_many :survey_response_queue_relationships, dependent: :destroy
  has_many :custom_queues, through: :survey_response_queue_relationships

  # Validations
  validates :survey_id, presence: true
  validates :contact_id, presence: true
  validates :contact_number, presence: true

  # Methods

end
