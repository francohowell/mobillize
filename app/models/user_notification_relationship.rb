class UserNotificationRelationship < ApplicationRecord

  # Relationships
  belongs_to :user
  belongs_to :notification

  # Validations
  validates :user_id, presence: true
  validates :notification_id, presence: true

  # Methods

end
