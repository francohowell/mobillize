class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception

    before_action :configure_permitted_parameters, if: :devise_controller?
    before_action :notification_check


    skip_before_action :notification_check, if: :devise_controller?
    helper_method :current_organization

    def notification_check
      if current_user
        @terms_need_displayed = !current_user.terms_up_to_date?
        if @terms_need_displayed
          @recent_term = Term.last
        end
        # Find all active notifications
        active_notifications = Notification.where("end_date > ?", DateTime.current)
        # Find all user notifications that don't have true acceptance attribute
        @unaccepted_notifications = []
        active_notifications.each do |note|
          note = Notification.find(note.id)
          un = UserNotificationRelationship.find_by(user: current_user, notification: note)
          if !un
            # Create new UserNotificationRelationship
            n = UserNotificationRelationship.new(user: current_user, notification: note)
            n.save
            # Add new UN info to array
            @unaccepted_notifications << {id: n.id, title: note.title, description: note.description}
          else
            # Add existing UN info to array if it hasn't been accepted by the user
            if !un.acceptance
              @unaccepted_notifications << {id: un.id, title: note.title, description: note.description}
            end
          end
        end
      end
    end

    def update_notification
      un = UserNotificationRelationship.find(params[:user_notification])
      un.update(acceptance: true)
    end

    def update_term
      current_user.update_terms
    end

    private def current_organization
      current_user.nil? ? nil : @current_organization ||= current_user.organization
    end

    protected

    def configure_permitted_parameters
    #   devise_parameter_sanitizer.permit(:sign_up, keys: [:username, :name, :terms, :location])
      devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name, :cell_phone, :can_send_blasts])
    end
end
