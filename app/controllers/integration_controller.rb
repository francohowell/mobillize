class IntegrationController < ApplicationController

    before_action :authenticate_user!

    def credentials
      @account_credentials = ApiAuthorization.where(organization_id: @current_user.organization.id)
    end

    def new_credential
      @api_cred = ApiAuthorization.new()
    end

    def create_credential
      

      api_cred = ApiAuthorization.new(auth_environment: params[:api_authorization][:auth_environment], note: params[:api_authorization][:note], organization_id: @current_user.organization.id)
      if api_cred.save
        flash[:success] = "Api Credential Created"
        redirect_to integration_credentials_path
      else
        flash[:alert] = api_cred.errors.full_messages.join("\n")
        redirect_to integration_new_credential_path
      end
    end

    def delete
      api_id = params[:id]
      credentials = ApiAuthorization.find_by_id(api_id)

      if credentials
        credentials.destroy
        flash[:success] = "Api Credential Deleted"
        redirect_to integration_credentials_path
      else
        flash[:alert] = "Could not find thee credential you would like to delete."
        redirect_to integration_credentials_path
      end

    end

  end
