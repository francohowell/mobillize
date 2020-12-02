class SystemValue < ApplicationRecord

    # Validations 
    validates :key, presence: true, length: { minimum: 2 }
    validates :value, presence: true, length: { minimum: 2 }
    validate :is_key_unique?

    # Methods
    def is_key_unique?
        if SystemValue.find_by_key(self.key)
            errors.add(:key, "is already taken, please choose another key.")
        end
    end

end
