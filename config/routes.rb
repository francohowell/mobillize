require 'sidekiq/web'

Rails.application.routes.draw do

  mount RailsAdmin::Engine => '/db_admin', as: 'rails_admin'

  authenticated :admin do
    mount Sidekiq::Web => '/sidekiq', as: 'sidekiq'
  end


  devise_for :users,  controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations',
    confirmations: 'users/confirmations',
    passwords: 'users/passwords'
  }

  devise_for :admins,  controllers: {
    sessions: 'admins/sessions',
    registrations: 'admins/registrations',
    confirmations: 'admins/confirmations',
    passwords: 'admins/passwords'
  }


  # You can have the root of your site routed with "root"
  authenticated :user do
    root 'dashboards#dashboard', as: :authenticated_root
  end

  root to: redirect('/users/sign_in')
  get 'login' => redirect('/')


  # root "landing#berightback"

  # Webhooks
  post 'webhook_endpoint/stripe_endpoint'


  # Chat
  get 'chat/overview'
  get 'chat/confirm_activate'
  get 'chat/activate_chat'
  get 'chat/feed'
  post 'chat/send_chat'
  get 'chat/new_chat'
  get 'chat/get_contacts'
  get 'chat/feed_check'
  get 'chat/message_check'
  delete 'chat/remove_chat_addon'

  # Global
  get 'message_check', to: 'application#message_check'
  get 'new_chat_message_check', to: 'application#new_chat_message_check'
  post 'update_notification', to: 'application#update_notification'
  post 'update_term', to: 'application#update_term'

  # Errors
  match "/404", :to => "pages#not_found_error", :via => :all
  match "/500", :to => "pages#internal_server_error", :via => :all

  # Surveys
  get 'survey/overview'
  get 'survey/new'
  post 'survey/create'
  get 'survey/questions'
  post 'survey/question_create'
  delete 'survey/question_delete'
  post 'survey/question_update'
  patch 'survey/question_update'
  get 'survey/edit'
  patch 'survey/update'
  get 'survey/:id/:contact_id/show', to: 'survey#show'
  post 'survey/submit'
  get 'survey/:id/completed', to: 'survey#completed'
  get 'survey/show'
  get 'survey/preview'
  get 'survey/completed'
  get 'survey/:survey_id/view', to: 'survey#view'
  get 'survey/view'
  get 'survey/:id/responses_export', to: 'survey#responses_export'
  get 'survey/responses_export'
  delete 'survey/delete'
  post 'survey/save_question_order'
  post 'survey/question_duplicate'
  get 'survey/answer_table'
  get 'survey/answers_upload'
  post 'survey/upload'
  post 'survey/upload_headers'
  post 'survey/update_import_questions'
  get 'survey/new_question'
  get 'survey/edit_question'
  get 'survey/advanced_validation'
  post 'survey/question_validation_update'
  post 'survey/link2feed_setup'
  get 'survey/validation_check'
  get 'survey/individual_response'

  # # API
  # mount V1::API => '/'
  # authenticate :user do
  #   mount GrapeSwaggerRails::Engine, at: "/documentation", as: 'api_docs'
  # end

  # Admin
  get 'admin_page/new_plan'
  post 'admin_page/create_plan'
  get 'admin_page/plan_overview'
  get 'admin_page/edit_plan'
  get 'admin_page/main_dashboard'
  get 'admin_page/monthly_overview', :musadmin
  get 'admin_page/yearly_overview'
  patch 'admin_page/edit_plan'
  get 'admin_page/usage_report'
  get 'admin_page/opt_out_queue'
  post 'admin_page/update_opt_out'
  get 'admin_page/reports'
  post 'admin_page/usage_report'
  post 'admin_page/customer_usage_report'
  post 'admin_page/customer_blast_report'
  post 'admin_page/new_account_report'
  get 'admin_page/organizations'
  get 'admin_page/manage_organization'
  post 'admin_page/update_notes'
  post 'admin_page/update_billing'
  delete 'admin_page/deactivate_organization'
  post 'admin_page/change_plan'
  get 'admin_page/system_notifications'
  post 'admin_page/create_notifcation'
  delete 'admin_page/delete_notification'
  get 'admin_page/edit_notification'
  patch 'admin_page/update_notification'
  get 'admin_page/change_organization_plan'
  get 'admin_page/review_organization_plan_change'
  post 'admin_page/process_plan_change'


  # Policies
  get 'policy/terms_conditions', :terms_conditions
  get 'policy/privacy', :privacy_policy
  get 'policy/spam', :spam_policy

  # Twilio
  post 'twilio/twilio_response'
  post 'twilio_response' => "twilio#twilio_response"

  # mGage
  post 'mgage/mgage_dr'
  post 'mgage/mgage_mo' => "mgage#mo"
  post 'mgage/mo'
  post 'mgage_dr' => "mgage#mgage_dr"
  post 'mgage_mo' => "mgage#mo"
  post 'mgage/mo' => "mgage#mo"
  post 'mgage/dr' => "mgage#mgage_dr"

  # InBox
  get 'inbox/overview'
  get 'inbox/overview_mobile'
  get 'inbox/feed'
  post 'inbox/twilio_send'
  get 'inbox/opt_outs'
  get 'inbox/export_responses'

  # Accounts
  get "account/new"
  post "account/create"

  # DELETE THIS LINE
  get "gallery/slick_carousel"

  # Organization
  get 'organization/edit'
  get 'organization/show'
  patch 'organization/update'
  get 'organization/new_admin'
  post 'organization/create_admin'
  post 'organization/deactivate_admin'
  post 'organization/activate_admin'

  # Contacts
  get 'contacts/new'
  get 'contacts/overview'
  post 'contacts/create'
  post 'contacts/upload'
  get 'contacts/upload_matching'
  post 'contacts/upload_headers'
  get 'contacts/upload_confirmation'
  get 'contacts/upload_overview'
  get 'contacts/show'
  get 'contacts/edit'
  patch 'contacts/update'
  get 'contacts/download'
  delete 'contacts/delete'
  post 'contacts/process_upload'
  get 'contacts/upload_failure'
  patch 'contacts/lookup_and_update'

  # Groups
  get 'groups/show'
  get 'groups/overview'
  get 'groups/new'
  post 'groups/create'
  delete 'groups/remove_individual_contact'
  delete 'groups/reset'
  get 'groups/contacts_export'
  delete 'groups/delete_contacts'
  get 'groups/edit'
  patch 'groups/update'
  delete 'groups/delete'

  # Keywords
  get 'keyword/overview'
  get 'keyword/new'
  get 'keyword/show'
  post 'keyword/create'
  post 'keyword/purchase'
  get 'keyword/edit'
  patch 'keyword/update'
  delete 'keyword/delete'
  get 'keyword/optin'
  post 'keyword/optin_create'
  get 'widget/:name', to: 'keyword#optin'
  get 'keyword/:name', to: 'keyword#optin'
  get '/widget/:name', to: 'keyword#optin'

  # Plan Management
  get 'plans/overview'
  get 'plans/checkout'
  post 'plans/update'
  get 'plans/keyword_management'
  post 'plans/cancel_downgrade'

    ## -- Webhooks -- ##
    post 'webhooks/bandwidth_hook'
    post 'webhooks/bandwidth_phone_order'

  # Add-On Management
  get 'addon/overview'
  get 'addon/checkout'
  post 'addon/subscribe'
  post 'addon/reactivate'
  delete 'addon/delete'

  # Billing Management
  get 'billing/overview'
  post 'billing/create'
  post 'billing/update'

  # Blast Management
  get 'blast/new'
  get 'blast/new_review'
  get 'blast/get_contacts'
  post 'blast/create'
  get 'blast/overview'
  get 'blast/show'
  post 'blast/purchase'
  get 'blast/edit'
  patch 'blast/update'
  delete 'blast/delete'

  # Reports Management
  get 'reports/overview'
  post 'reports/create_blast_report'

  # Dashboard Management
  get "dashboards/dashboard", :dashboard

  # Other Pages
  get "pages/not_found_error"
  get "pages/internal_server_error"
  get "pages/empty_page"

  get "landing/index"
  get 'landing/berightback'
  get 'landing/privacy'
  get 'landing/spam'


  # Potentially Used Views
  # get "layoutsoptions/index"
  # get "layoutsoptions/off_canvas"

  get 'queue/overview'
  get 'queue/:queue_id/view', to: 'queue#view'
  get 'queue/view'
  get 'queue/edit'
  get 'queue/new'
  post 'queue/create'
  get 'queue/complete_appointment'
  get 'queue/export'
  delete 'queue/delete'
  delete 'queue/empty'
end
