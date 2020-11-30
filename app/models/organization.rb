class Organization < ApplicationRecord
    mount_uploader :logo, LogoUploader
    include PaymentProcessor

    # Relationships
    has_many :users, dependent: :destroy
    has_many :contacts, dependent: :destroy
    has_many :groups, dependent: :destroy
    has_many :keywords, dependent: :destroy
    has_many :organization_phone_relationships, dependent: :destroy
    has_many :phone_numbers, through: :organization_phone_relationships
    has_one :stripe_account, dependent: :destroy
    has_many :blasts, dependent: :destroy
    has_many :contact_uploads, dependent: :destroy
    has_many :survey_answer_uploads, dependent: :destroy
    has_many :organization_contact_relationships, dependent: :destroy
    has_many :surveys, dependent: :destroy

    # Validations
    validates :name, presence: true, length: { minimum: 2}
    validates :industry, presence: true, length: { minimum: 2}
    validates :size, presence: true, length: { minimum: 2 }
    validates :timezone, presence: true
    validates :street, allow_blank: true, length: { minimum: 2}
    validates :city, allow_blank: true, length: { minimum: 2}
    validates :state_providence, allow_blank: true, length: { minimum: 2}
    validates :country, allow_blank: true, length: { minimum: 2}
    validates :postal_code, allow_blank: true, length: { minimum: 5}
    validates :start_date, presence: true 
    validates :annual_credits, presence: true, numericality: { greater_than_or_equal_to: 0 }

    validates_integrity_of :logo
    validates_processing_of :logo

    after_save :inactive_change

    ##--> Methods

    # Returns Credit Usage 
    def current_credit_usage
        t = DateTime.now.utc
        # Determine the active year 
        if self.start_date > t 
            # Account Start Date Is In The Future 
            return annual_credits
        end 

        # Obtain Date Ranges 
        years_past_start_date = ((t - self.start_date) / 365).floor
        date_range_start = self.start_date
        date_range_end = self.start_date + 1.year
        # Make adjustments based on the years past
        if years_past_start_date > 0 
            date_range_start = self.start_date + years_past_start_date
            date_range_end = date_range_start + 1.year
        end
    
        current_blasts_credits = self.blasts.where("send_date_time BETWEEN ? AND ?", date_range_start, date_range_end).pluck("SUM(cost)")
        
        current_chats_credits = self.chats.where("created_at BETWEEN ? AND ?", date_range_start, date_range_end).pluck("SUM(cost)")

        return current_blasts_credits + current_chats_credits
    end

    def inactive_change
        if self.active == false
            # Twilio Release Phone Number
            long_codes = self.phone_numbers.where(long_code: true, global: false, demo: false)
            twilio_master_service = TwilioMasterService.new()
            for long_code in long_codes
                release_response = twilio_master_service.release_number(long_code.service_id)
                if !release_response[:success]
                    Honeybadger.notify("Failed to release long code with id: #{long_code.id}. | #{release_response[:response]}", class_name: "Organization Model -> Inactive Change", error_message: release_response[:response])
                else
                    # Delete Phone Number
                    if !long_code.destroy
                        Honeybadger.notify("Failed to destroy longcode with id: #{long_code.id}", class_name: "Organization Model -> Inactive Change", error_message: long_code.errors.full_messages)
                    end
                end
            end
        end
    end

    def groups_with_contacts
        gc_array = []
        for g in self.groups
            if g.get_contact_count > 0
                gc_array.push(g)
            end
        end
        return gc_array
    end

    def state_code
        s = self.state_providence
        if s
            s = s.downcase
            state_hash = {"Alabama" => "AL",
                "alaska" => "AK",
                "arizona" => "AZ",
                "arkansas" => "AR",
                "california" => "CA",
                "colorado" => "CO",
                "connecticut" => "CT",
                "delaware" => "DE",
                "district of columbia" => "DC",
                "florida" => "FL",
                "georgia" => "GA",
                "hawaii" => "HI",
                "idaho" => "ID",
                "illinois" => "IL",
                "indiana" => "IN",
                "iowa" => "IA",
                "kansas" => "KS",
                "kentucky" => "KY",
                "louisiana" => "LA",
                "maine" => "ME",
                "maryland" => "MD",
                "massachusetts" => "MA",
                "michigan" => "MI",
                "minnesota" => "MN",
                "mississippi" => "MS",
                "missouri" => "MO",
                "montana" => "MT",
                "nebraska" => "NE",
                "nevada" => "NV",
                "new hampshire" => "NH",
                "new jersey" => "NJ",
                "new mexico" => "NM",
                "new york" => "NY",
                "north carolina" => "NC",
                "north dakota" => "ND",
                "ohio" => "OH",
                "oklahoma" => "OK",
                "oregon" => "OR",
                "pennsylvania" => "PA",
                "rhode island" => "RI",
                "south carolina" => "SC",
                "south dakota" => "SD",
                "tennessee" => "TN",
                "texas" => "TX",
                "utah" => "UT",
                "vermont" => "VT",
                "virginia" => "VA",
                "washington" => "WA",
                "west virginia" => "WV",
                "wisconsin" => "WI",
                "wyoming" => "WY"}
            return state_hash[s]
        else
            return nil
        end
    end

    def keyword_names
        return self.keywords.pluck(:name)
    end

    def credits_left
        credits_left = self.annual_credits - self.current_credit_usage
    end

    def is_addon_active?(addon_name)
      addon = self.add_ons.find_by(name: addon_name)
      active = OrganizationAddOnRelationship.where(add_on: addon, organization: self, status: 'active')
      !active.empty? ? true : false
    end

end
