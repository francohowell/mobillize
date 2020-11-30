class SurveyQueueRelationship < ApplicationRecord
  belongs_to :survey
  belongs_to :custom_queue
end
