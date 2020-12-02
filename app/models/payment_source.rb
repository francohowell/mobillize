class PaymentSource < ApplicationRecord

    # Relationships
    belongs_to :stripe_account

    # Validations 
    validates :card_id, presence: true, length: { minimum: 2 }
    validates :brand, presence: true, length: { minimum: 2 }
    validates :exp_month, presence: true, length: { minimum: 2 }
    validates :exp_year, presence: true, length: { minimum: 2 }
    validates :last4, presence: true, length: { minimum: 2 }
    validates :stripe_creation, presence: true, length: { minimum: 2 }

end
