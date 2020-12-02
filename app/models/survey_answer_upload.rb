class SurveyAnswerUpload < ApplicationRecord
    mount_uploader :file, CsvUploader

    # Relationships
    belongs_to :organization
    belongs_to :user

    # Validations
    validates :file, presence: true
    validates_integrity_of :file
    validates_processing_of :file

end
