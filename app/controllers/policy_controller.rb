class PolicyController < ApplicationController
  layout 'empty'
  skip_before_action :verify_authenticity_token
  skip_before_action :notification_check
  skip_before_action :active_billing_status
  protect_from_forgery with: :null_session

  def terms_conditions
    @term = Term.where("publication_date <= ?", Time.now).order("publication_date DESC").first
  end

  def privacy
  end

  def spam
  end
end
