class OrganizationController < ApplicationController
  before_action :authenticate_user!

  def show
    @organization = current_user.organization
    @admins = @organization.users
  end

  def edit
    @organization = current_user.organization
  end

  def update
    @organization = current_user.organization

    update_hash = Hash.new

    if params[:organization][:name]
      update_hash["name"] = params[:organization][:name]
    end

    if params[:organization][:street]
      update_hash["street"] = params[:organization][:street]
    end

    if params[:organization][:street2]
      update_hash["street2"] = params[:organization][:street2]
    end

    if params[:organization][:city]
      update_hash["city"] = params[:organization][:city]
    end

    if params[:organization][:state_providence]
      update_hash["state_providence"] = params[:organization][:state_providence]
    end
    
    if params[:organization][:postal_code]
      update_hash["postal_code"] = params[:organization][:postal_code]
    end
    
    if params[:organization][:industry]
      update_hash["industry"] = params[:organization][:industry]
    end

    if params[:organization][:size]
      update_hash["size"] = params[:organization][:size]
    end

    if params[:organization][:logo]
      update_hash["logo"] = params[:organization][:logo]
    end

    if params[:timezone]
      update_hash["timezone"] = params[:timezone]
    end

    if !@organization.update(update_hash)
      flash[:alert] = "Failed to update your organization details. #{@organization.errors.full_messages}"
      redirect_to organization_edit_path()
      return
    else 
      flash[:success] = "Organization was updated successfully."
      redirect_to organization_show_path()
    end

  end

  def new_admin 
    @organization = current_user.organization
    @new_user = User.new
  end

  def create_admin 
    @new_user = User.new(first_name: params[:user][:first_name], last_name: params[:user][:last_name], password: params[:user][:password], password_confirmation: params[:user][:password_confirmation], email: params[:user][:email], cell_phone: params[:user][:cell_phone], organization_id: current_user.organization.id, active: true)
    if !@new_user.save
      flash[:alert] = "Failed to create a new admin for your organizaiton. #{@new_user.errors.full_messages}"
      redirect_to organization_new_admin_path()
    else
      flash[:success] = "New admin has been created."
      redirect_to organization_show_path()
    end
  end

  def deactivate_admin 
    @user = User.find_by_id(params[:id])
    if @user
      if @user.organization.id == current_user.organization.id 
        @user.active = false 
        if !@user.save 
          flash[:alert] = "Failed to deactivate admin for your organizaiton. #{@user.errors.full_messages}"
        else
          flash[:success] = "Successfully deactivate admin for your organizaiton."
        end
        redirect_to organization_show_path()
      end
    end
  end

  def activate_admin 
    @user = User.find_by_id(params[:id])
    if @user
      if @user.organization.id == current_user.organization.id 
        @user.active = true 
        if !@user.save 
          flash[:alert] = "Failed to deactivate admin for your organizaiton. #{@user.errors.full_messages}"
        else
          flash[:success] = "Successfully deactivate admin for your organizaiton."
        end
        redirect_to organization_show_path()
      end
    end
  end

end
