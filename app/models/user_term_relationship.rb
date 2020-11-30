class UserTermRelationship < ApplicationRecord

    # Relationships 
    belongs_to :user
    belongs_to :term 

    # Validations 
    validates :user_id, presence: true
    validates :term_id, presence: true 
    validates :acceptance_date, presence: true 
    validate :acceptance_date_check 

    # Methods 

    private 

    # Validation Methods 
    def acceptance_date_check
        today = Time.now.utc
        logger.debug("Today --> #{today} | Acceptance Date --> #{acceptance_date}")
        if acceptance_date.year == today.year && acceptance_date.month == today.month && acceptance_date.day == today.day 
            return true 
        else
            errors.add(:acceptance_date, "cannot be before today or after today.")
        end
    end
end
