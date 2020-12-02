class StripeAccount < ApplicationRecord

    # Relationships 
    belongs_to :organization
    has_one :payment_source, dependent: :destroy

    # Validations
    validates :stripe_id, presence: true, length: { minimum: 2 }
    validates :stripe_creation, presence: true
    validates :payment_source_id, presence: true 
    validates :payment_source_exp_month, presence: true
    validates :payment_source_exp_year, presence: true
    validates :payment_source_type, presence: true
    validates :payment_source_last4, presence: true
    validates :payment_source_name, presence: true 

    # Methods
    def favicon_name 
        case self.payment_source_type
        when "Visa"
            return "visa"
        when "American Express"
            return "amex"
        when "Discover"
            return "discover"
        when "MasterCard"
            return "mastercard"
        else
            return "vcard"
        end
    end


end
      