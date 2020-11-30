class BlastAttachment < ApplicationRecord

    mount_uploader :attachment, AttachmentUploader

    # Relations 
    belongs_to :blast

    # Validations 
    validates :attachment, presence: true
    validates_integrity_of :attachment
    validates_processing_of :attachment

end
