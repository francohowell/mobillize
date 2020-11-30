class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  # Session Management
  def authenticatable_salt
    "#{super}#{session_token}"
  end

  def invalidate_session!
    self.session_token = SecureRandom.hex
  end

  # Event Triggers
  after_create_commit :create_terms_relationship

  # Relationships
  belongs_to :organization
  has_many :user_term_relationships
  has_many :terms, through: :user_term_relationships
  has_many :contact_uploads
  has_many :survey_answer_uploads
  has_many :user_notification_relationships
  has_many :notifications, through: :user_notification_relationships

  # Validations
  validates :first_name, presence: true, length: { minimum: 2 }
  validates :last_name, presence: true, length: { minimum: 2 }
  validates :cell_phone, presence: true, phone: { possible: true, types: [:voip, :mobile] }
  #validates :can_send_blasts, presence: true

  # Methods
  def name
    return "#{first_name} #{last_name}"
  end

  def terms_up_to_date?
    active_terms = Term.all.order("publication_date DESC").first
    if self.user_term_relationships.find_by_term_id(active_terms.id)
      return true
    else
      return false
    end
  end

  def update_terms
    active_terms = Term.all.order("publication_date DESC").first
    tms = self.user_term_relationships.build(term_id: active_terms.id, user_id: id, acceptance_date: Time.now.utc)
    if !tms.save
      return tms.errors.full_messages
    end

    return nil
  end

  def active_for_authentication?
    #remember to call the super
    #then put our own check to determine "active" state using
    #our own "is_active" column
    super
    if self.active == true && self.organization.active == true
      return true
    else
      return false
    end
  end

  private

  def create_terms_relationship
    active_terms = Term.all.order("publication_date DESC").first
    tms = self.user_term_relationships.build(term_id: active_terms.id, user_id: id, acceptance_date: Time.now.utc)
    if !tms.save
      raise ActiveRecord::RecordInvalid.new(self)
    end
  end

end
