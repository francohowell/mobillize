# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]
  skip_before_action :notification_check

  layout 'empty', only: [:new, :create]

  # GET /resource/sign_up
  def new
    @term = Term.last
    if params[:user]
      @first_name = params[:user][:first_name]
      @last_name = params[:user][:last_name]
      @email = params[:user][:email]
      @cell_phone = params[:user][:cell_phone]
      @org_name = params[:user][:org_name]
      @industry = params[:user][:industry]
      @size = params[:user][:size]
      @timezone = params[:user][:timezone]
    end
    super
  end

  # POST /resource
  def create

    error_occurred = false
    ActiveRecord::Base.transaction do

      # Create The Organization First
      o = Organization.new(name: params[:user][:org_name], industry: params[:user][:industry], size: params[:user][:size], timezone: params[:user][:time_zone], previous_plan_id: 0 )

      if !o.save
        logger.error("Failed to create new organization: #{o.errors.full_messages}")
        flash[:alert] = o.errors.full_messages
        error_occurred = true
        raise ActiveRecord::Rollback
      end

      # Attach The Short Code To The Organization
      short_code = PhoneNumber.find_by(long_code: false)
      new_short_code_relationship =  OrganizationPhoneRelationship.new(organization_id: o.id, phone_number_id: short_code.id, mass_outgoing: true)
      if !new_short_code_relationship.save
        logger.error("Failed to setup a new relationship with short code for organization #{org.id} and number #{short_code.id}")
        logger.error(new_short_code_relationship.erros.full_messages)
        flash[:alert] = "An error has occured while setting up your account. Please contact customer support."
        error_occurred = true
        raise ActiveRecord::Rollback
      end

      # Generate Keyword
      keyword_generated = "MUSDEMO#{o.id}"
      i = 0
      while Keyword.find_by_name(keyword_generated) do
        keyword_generated = "MUS#{i}DEMO#{o.id}"
        i += 1
      end
      keyword_created = Keyword.new(active: true, description: "Demo Assigned Keyword", name: keyword_generated.downcase, user_id: 0, organization_id: o.id)

      if !keyword_created.save
        logger.error("Failed to create an auto-generated keyword: #{keyword_created.errors.full_messages}")
        flash[:alert] = "An error has occured while setting up your account. Please contact customer support."
        error_occurred = true
        raise ActiveRecord::Rollback
      end

      # Create The User
      # Remove the attributes that are not user based.
      params[:user].delete :org_name
      params[:user].delete :industry
      params[:user].delete :size
      params[:user][:organization_id] = o.id

      u = User.new(first_name: params[:user][:first_name], last_name: params[:user][:last_name], active: true, cell_phone: params[:user][:cell_phone], email: params[:user][:email], password: params[:user][:password], password_confirmation: params[:user][:password_confirmation], can_send_blasts: params[:user][:can_send_blasts],organization_id: o.id)

      if !u.save
        flash[:alert] = u.errors.full_messages
        error_occurred = true
        raise ActiveRecord::Rollback
      end

    end

    # Process The State Of The Call
    if error_occurred
      redirect_to new_user_registration_path(user: { org_name: params[:user][:org_name], industry: params[:user][:industry], size: params[:user][:size], time_zone: params[:user][:time_zone], first_name: params[:user][:first_name], last_name: params[:user][:last_name], email: params[:user][:email], cell_phone: params[:user][:cell_phone]})
      return
    else
      redirect_to root_path
      return
    end

  end

  # GET /resource/edit
  def edit
    super
  end

  # PUT /resource
  def update
    # if params[:first_name]
    #   @current_user.first_name = params[:first_name]
    # end
    # if !@current_user.save
    #   flash[:error] = @current_user.errors.full_messages
    # end
    super

    if params[:can_send_blasts]
      @current_user.can_send_blasts = params[:can_send_blasts]
    end
  end

  # DELETE /resource
  def destroy
    super
  end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  def cancel
    super
  end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :cell_phone, :org_name, :industry, :size, :organization_id])
  end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_account_update_params
    #  devise_parameter_sanitizer.permit(:account_update, keys: [:attribute])
+    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name, :cell_phone, :can_send_blasts])
  end

  # The path used after sign up.
  def after_sign_up_path_for(resource)
    super(resource)
  end

  # The path used after sign up for inactive accounts.
  def after_inactive_sign_up_path_for(resource)
    super(resource)
  end

  def after_update_path_for(resource)
    edit_user_registration_path
  end

end
