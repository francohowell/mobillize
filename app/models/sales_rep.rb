class SalesRep < ApplicationRecord

    # Validations 
    validates :first_name, presence: true
    validates :last_name, presence: true
    validates :email, presence: true
    validates :phone, presence: true

    has_many :organizations

    def name 
        return "#{first_name} #{last_name}"
    end

end
