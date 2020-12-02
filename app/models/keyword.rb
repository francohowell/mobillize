class Keyword < ApplicationRecord
    mount_uploader :opt_in_media, AttachmentUploader

    # Relations 
    belongs_to :organization
    has_many :keyword_group_relationships,  dependent: :destroy
    has_many :groups, through: :keyword_group_relationships
    has_many :keyword_survey_relationships, dependent: :destroy 
    has_many :surveys, through: :keyword_survey_relationships 

    # Validations 
    validates :name, presence: true, length: { minimum: 2 }, format: { without: /\s/, message: "must not contain spaces."}
    validates :active, presence: true
    validates :help_text, allow_blank: true, length: { minimum: 2, maximum: 1000 }
    validates :invitation_text, allow_blank: true, length: { minimum: 2 }
    validates :opt_in_text, allow_blank: true, length: {minimum: 2, maximum: 1000 }
    validate :is_keyword_unique?, on: :create
    

    # Methods
    def original_url 
        base_url + original_fullpath
    end

    def to_param
        name.parameterize
    end

    def is_keyword_unique?
        if Keyword.find_by_name(self.name)
            errors.add(:keyword, "is already taken, please choose another keyword.")
        end
    end


end
