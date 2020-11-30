class Notification < ApplicationRecord

  # Relationships
  has_many :user_notification_relationships, dependent: :destroy
  has_many :users, through: :user_notification_relationships

  # Validations
  validates :title, presence: true
  validates :description, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true

  # Methods

end
