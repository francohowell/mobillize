class Blast < ApplicationRecord

    # Relations 
    belongs_to :organization
    has_many :blast_attachments, dependent: :destroy
    accepts_nested_attributes_for :blast_attachments
    has_many :blast_contact_relationships, dependent: :destroy
    has_many :blast_group_relationships, dependent: :destroy
    has_many :groups, through: :blast_group_relationships
    
    # Validations 
    validates :message, presence: true, length: { maximum: 1600 }
    validates :keyword_id, presence: true 
    validates :keyword_name, presence: true, length: { minimum: 2 }
    validates :user_id, presence: true
    validates :send_date_time, presence: true 
    validate :is_send_date_time_valid?

    before_destroy :remove_sidekiq_job

    # Methods 
    def remove_sidekiq_job
        if self.job_id
            job = Sidekiq::ScheduledSet.new.find_job(self.job_id)
            if job
                job.delete
            end
        end
    end

    def is_send_date_time_valid?
        current_time = Time.now.utc
        if self.send_date_time.day != current_time.day && self.send_date_time.month != current_time.month && self.send_date_time.year != current_time.year
            if self.send_date_time < current_time
                errors.add(:send_date_time, "cannot be in the past, must be today or later.")
            end
        end
    end

    def contact_ids
        self.blast_contact_relationships.pluck(:contact_id)
    end

    def contact_hard_count
        self.blast_contact_relationships.count
    end

    def outgoing_message 
        return "#{self.keyword_name.upcase} #{self.message}"
    end

    def repeating_send_dates 
        # Immediate Repeat 
        date_array = []
        if self.repeat
            initial_start_date = self.created_at

            if self.send_date_time 
                initial_start_date = self.send_date_time
            end

            logger.info("BASE DATE :::: #{initial_start_date.to_datetime}")


            if self.repeat == "Daily"
                logger.info("DAILY DATE COMPARE:::: #{initial_start_date.to_datetime} | #{self.repeat_end_date.to_datetime.end_of_day}")

                (initial_start_date.to_datetime..self.repeat_end_date.to_datetime).each do |date|
                    date_array.push(date)
                end
            elsif self.repeat == "Weekly"
                iterating_date = initial_start_date
                logger.info("WEEKLY DATE COMPARE:::: #{iterating_date.to_datetime} | #{self.repeat_end_date.to_datetime.end_of_day}")
                while iterating_date.to_datetime <= self.repeat_end_date.to_datetime.end_of_day do
                    date_array.push(iterating_date)
                    iterating_date = iterating_date + 7.days
                end
            else #Default Monthly
                iterating_date = initial_start_date
                logger.info("MONTHLY DATE COMPARE:::: #{iterating_date.to_datetime} | #{self.repeat_end_date.to_datetime.end_of_day}")
                while iterating_date.to_datetime <= self.repeat_end_date.to_datetime.end_of_day do
                    date_array.push(iterating_date)
                    iterating_date = iterating_date + 1.months
                end
            end
        end
        return date_array
    end

end
