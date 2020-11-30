class Term < ApplicationRecord

    # Relationships 
    has_many :user_term_relationships
    has_many :users, through: :user_term_relationships

    # Validations 
    validates :title, presence: true, length: { minimum: 2 }
    validates :sub_title, presence: true, length: { minimum: 2 }
    validates :content, presence: true, length: { minimum: 50 }
    validates :publication_date, presence: true 
    validate :publication_date_check 

    # Methods

    private 

    # Validation Methods
    def publication_date_check
        today = Time.now.utc
        if publication_date.year == today.year && publication_date.month == today.month && publication_date.day == today.day
            return true
        else
            errors.add(:publication_date, "Cannot be before today or after today.")
        end
    end
end
