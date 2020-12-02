class CustomQueue < ApplicationRecord
  # Relationships
  belongs_to :organization
  has_many :survey_queue_relationships, dependent: :destroy
  has_many :surveys, through: :survey_queue_relationships
  has_many :survey_response_queue_relationships, dependent: :destroy
  has_many :survey_responses, through: :survey_response_queue_relationships
  

  # Validations
  
  validates :name, presence: true, length: { minimum: 5 }
  validates_numericality_of :capacity, greater_than_or_equal_to: 1, less_than_or_equal_to: 1000, message: 'must be between 1 & 1000'
  #  validates :start_date_time, presence: true
  #  validates :end_date_time, presence: true

  # Methods
  def survey_list
    self.surveys.pluck(:name).join(', ')
  end
  
  def appointment_count
    SurveyResponseQueueRelationship.where(custom_queue_id: self.id).count
  end
end
