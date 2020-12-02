class KeywordController < ApplicationController
  include Pagy::Backend
  before_action :authenticate_user!, except: [:optin, :optin_create]
  skip_before_action :notification_check, except: [:overview, :new, :show, :create, :purchase, :edit, :update, :delete]
  after_action :allow_iframe, only: [:optin, :opt_in_create]

  def overview
    @keyword_count = current_organization.keywords.count
    if params[:search]
      @pagy, @kw_search = pagy(current_user.organization.keywords.where("name ILIKE :search", search: "%#{params[:search]}%"), limit: 25)
    else
      @pagy, @kw_search = pagy(current_user.organization.keywords, limit: 25)
    end
  end

  def new
    @organization = current_user.organization
    @payment_details = @organization.stripe_account.nil? ? false : true
    @kw = Keyword.new(name: params[:name], description: params[:description], help_text: params[:help_text], invitation_text: params[:invitation_text], opt_in_text: params[:opt_in_text], opt_out_text: params[:opt_out_text])
    @groups = @organization.groups
    @contacts = @organization.contacts.where(active: true)
    @keyword_count = @organization.keywords.count
    @keyword_rentals = @organization.keywords.where.not(stripe_id: nil)
  end

  def show
    @kw = current_user.organization.keywords.find_by_id(params[:id])
    @created_by_user = User.find_by_id(@kw.user_id)
  end

  def create
    name = params[:keyword][:name]
    description = params[:keyword][:description]
    invitation = params[:keyword][:invitation_text]
    active = true
    opt_in = params[:keyword][:opt_in_text]
    opt_in_media = params[:keyword][:opt_in_media]
    help_text = params[:keyword][:help_text]
    organization = current_user.organization

    kw = Keyword.new(name: name.downcase, description: description, invitation_text: invitation, active: active, opt_in_text: opt_in, opt_in_media: opt_in_media, help_text: help_text, organization: organization, user_id: current_user.id)

    if name.downcase.match("musdemo")
      flash[:alert] = "Please choose another keyword, #{kw.name.downcase} has been taken."
      redirect_to keyword_new_path(name: name, description: description, invitation_text: invitation, opt_in_text: opt_in)
      return
    end

    if !kw.save
      flash[:alert] = kw.errors.full_messages.join("\n")
      redirect_to keyword_new_path(name: name, description: description, invitation_text: invitation, opt_in_text: opt_in)
    else
      if params[:admins]
        for admin_id in params[:admins]
          ka = KeywordAdmin.new(keyword: kw, contact_id: admin_id)
          if !ka.save
            kw.delete
            flash[:alert] = "Failed to created Keyword.\n" + ka.errors.full_messages.join("\n")
            redirect_to keyword_new_path
          end
        end
      end

      if params[:groups]
        for group_id in params[:groups]
          kg = KeywordGroupRelationship.new(keyword: kw, group_id: group_id)
          if !kg.save
            kw.delete
            flash[:alert] = "Failed to created Keyword.\n" + kg.errors.full_messages.join("\n")
            redirect_to keyword_new_path
          end
        end
      end

      flash[:success] = "Keyword has been created."
      redirect_to keyword_new_path
    end
  end

  def purchase
    if params[:keyword]
      name = params[:keyword][:name]
      description = params[:keyword][:description]
      invitation = params[:keyword][:invitation_text]
      active = true
      opt_in = params[:keyword][:opt_in_text]
      help_text = params[:keyword][:help_text]
      organization = current_user.organization
      opt_in_media = params[:keyword][:opt_in_media]

      kw = Keyword.new(name: name.downcase, description: description, invitation_text: invitation, active: active, opt_in_text: opt_in, opt_in_media: opt_in_media, help_text: help_text, organization: organization, user_id: current_user.id)

      if !kw.save
        flash[:alert] = kw.errors.full_messages.join("\n")
        redirect_to keyword_new_path(name: name, description: description, invitation_text: invitation, opt_in_text: opt_in)
      else

        # Purchase Keyword Subscription
        subscription_keyword_upgrade = process_keyword_subscription(kw.name)

        if !subscription_keyword_upgrade
          kw.delete
          #flash[:alert] = "An error has occured creating the keyword subscription. Please contact customer support."
          redirect_to keyword_new_path()
          return
        end

        if !kw.update(stripe_id: subscription_keyword_upgrade.id, purchase_date: DateTime.now)
          flash[:alert] = "An error has occured creating the keyword subscription. Please contact customer support."
          redirect_to keyword_new_path()
          return
        end

        # All Other relationships
        if params[:admins]
          for admin_id in params[:admins]
            ka = KeywordAdmin.new(keyword: kw, contact_id: admin_id)
            if !ka.save
              kw.delete
              flash[:alert] = "Failed to created Keyword.\n" + ka.errors.full_messages.join("\n")
              redirect_to keyword_new_path()
            end
          end
        end

        if params[:groups]
          for group_id in params[:groups]
            kg = KeywordGroupRelationship.new(keyword: kw, group_id: group_id)
            if !kg.save
              kw.delete
              flash[:alert] = "Failed to created Keyword.\n" + kg.errors.full_messages.join("\n")
              redirect_to keyword_new_path()
            end
          end
        end

        flash[:success] = "Your new keyword has been purchased!"
        redirect_to keyword_overview_path()

      end
    else # Used to process existing keywords that are going to be subscribed to on a downgrade.
      kw = Keyword.find_by_id(params[:keyword_id])

       # Purchase Keyword Subscription
       subscription_keyword_upgrade = process_keyword_subscription(kw.name)

       if !subscription_keyword_upgrade
         flash[:alert] = "An error has occured creating the keyword subscription. Please contact customer support."
         redirect_to plans_keyword_management_path(plan_id: params[:plan_id])
         return
       end

       if !kw.update(stripe_id: subscription_keyword_upgrade.id, purchase_date: DateTime.now)
         flash[:alert] = "An error has occured creating the keyword subscription. Please contact customer support."
         redirect_to plans_keyword_management_path(plan_id: params[:plan_id])
         return
       end

       flash[:success] = "Your new keyword has been changed to a subsdcription!"
       redirect_to plans_keyword_management_path(plan_id: params[:plan_id])
       return
    end
  end

  def edit
    @kw = current_user.organization.keywords.find_by_id(params[:id])
    if !@kw
      flash[:alert] = "We could not find the keyword you were looking for."
      redirect_to keyword_overview_path
      return
    end
    @groups = current_user.organization.groups
    @existing_groups = @kw.groups
    @admins = current_user.organization.contacts.where(active: true)
  end

  def update
    @demo = current_user.organization.plan.name == "Demo" ? true : false
    if !@demo
      success = true

      @kw = current_user.organization.keywords.find_by_id(params[:id])
      # if params[:keyword][:name]
      #   @kw.name = params[:keyword][:name].downcase
      # end

      if params[:keyword][:description]
        @kw.description = params[:keyword][:description]
      end

      if params[:keyword][:opt_in_text]
        @kw.opt_in_text = params[:keyword][:opt_in_text]
      end

      if params[:keyword][:help_text]
        @kw.help_text = params[:keyword][:help_text]
      end

      if params[:keyword][:invitation_text]
        @kw.invitation_text = params[:keyword][:invitation_text]
      end

      if params[:keyword][:opt_in_media]
        @kw.opt_in_media = params[:keyword][:opt_in_media]
      end

      if !@kw.save
        success = false
        flash[:alert] = @kw.errors.full_messages
        redirect_to keyword_edit_path(id: params[:id])
        return
      end


      if params[:groups]
        # Adding Groups When There Are Existing SubGroups
        ex_group_ids = @kw.groups.ids

        for g_id in params[:groups]
          if ex_group_ids.include?(g_id)
            ex_group_ids.delete(g_id)
          end
        end

        # Any values left over from the sub_group_ids need to be deleted as these were removed by the user.
        for remaining_id in ex_group_ids
          @kw.keyword_group_relationships.find_by_group_id(remaining_id).delete
        end

        # Adding Groups
        for g_id in params[:groups]
          group = current_user.organization.groups.find_by_id(g_id)
          if group
            kw_group_relation = KeywordGroupRelationship.create(group: group, keyword: @kw)
            if !kw_group_relation
              success = false
              flash[:alert] = kw_group_relation.errors.full_messages.join("\n")
              redirect_to keyword_edit_path(id: params[:id])
              return
            end
          else
            success = false
            flash[:alert] = "Could not find group to add to keyword."
            redirect_to keyword_edit_path(id: params[:id])
            return
          end
        end
      else
        # Removing Groups When There Is No OtherGroups Params
        if @kw.groups
          @kw.keyword_group_relationships.destroy_all
        end
      end

      if success
        flash[:success] = "Keyword has been updated!"
        redirect_to keyword_edit_path(id: params[:id])
        return
      end
    else
      success = false
      flash[:alert] = "Please upgrade your account to make any changes to your keyword."
      redirect_to keyword_overview_path()
      return
    end

  end

  def delete
    @demo = current_user.organization.plan.name == "Demo" ? true : false
    if !@demo
      @kw = current_user.organization.keywords.find_by_id(params[:id])
      if @kw.stripe_id
        # Purchase Keyword Subscription
        canceled_keyword = remove_keyword_subscription(@kw.stripe_id)

        if !canceled_keyword
          redirect_to keyword_edit_path(id: @kw.id)
          return
        end
      end

      if @kw.destroy
        flash[:success] = "You have successfully removed your keyword."
        redirect_to keyword_overview_path
      else
        flash[:error] = @kw.errors.full_messages
        redirect_to keyword_edit_path(id: params[:id])
      end
    else
      flash[:alert] = "Please upgrade your account to make any changes to your keyword."
      redirect_to keyword_overview_path()
    end
  end

  def optin
    if params[:id]
      @kw = Keyword.find_by_id(params[:id])
    elsif  params[:name]
      @kw = Keyword.find_by_name(params[:name].downcase)
    end
    render layout: "empty"
  end

  def optin_create
    # Obtain the keyword
    @kw = Keyword.find_by_id(params[:id])
    # Create the contact if it does not exist
    # Parse the cell phone number
    stripped_number = Contact.new.strip_number(params[:cell_phone])
    @c = Contact.find_by(cell_phone: stripped_number, organization_id: @kw.organization.id)
    if !@c
      @c = Contact.new(first_name: params[:first_name], last_name: params[:last_name], cell_phone: stripped_number, primary_email: params[:primary_email], secondary_email: params[:secondary_email], company_name: params[:company_name], organization: @kw.organization, active: true)
      if !@c.save
        logger.info("Opt In Failure: #{@c.errors.full_messages}")
        flash[:error] = "Could not add you to the list, please contact #{@kw.organization.name}"
        redirect_to keyword_optin_path(id: @kw.id)
        return
      end
    else
      # Update any additional details about the contact
      @c.first_name = params[:first_name]
      @c.last_name = params[:last_name]
      if params[:primary_email]
        @c.primary_email = params[:primary_email]
      end
      if params[:secondary_email]
        @c.secondary_email = params[:secondary_email]
      end
      if params[:company_name]
        @c.company_name = params[:company_name]
      end
      @c.save
    end

    # Add them to the correct groups
    for g in @kw.groups
      # Check to see if they are already part of the group
      if !g.contacts.find_by_id(@c.id)
        gcr = GroupContactRelationship.new(group: g, contact: @c)
        if !gcr.save
          flash[:error] = "Could not add you to the list, please contact #{@kw.organization.name}"
          redirect_to keyword_optin_path(id: @kw.id)
          return
        end
      end
    end


    default_opt_in_message_obj = SystemValue.find_by_key("default_opt_in_text")
    additional_opt_out_text = SystemValue.find_by_key("additional_opt_out_text")
    opt_in_text = ""

    keyword_surveys = @kw.surveys
    if !keyword_surveys.empty?
      for survey in keyword_surveys
        if survey.start_date_time <= DateTime.now && survey.end_date_time >= DateTime.now
          new_url ="https://#{Rails.application.routes.default_url_options[:host]}/survey/#{survey.id}/#{@c.id}/show"

          if opt_in_text.blank?
            opt_in_text = "#{survey.start_message} #{new_url}"
          else
            opt_in_text += " #{survey.start_message} #{new_url}"
          end

        end
      end
    else
      if @kw.opt_in_text
        opt_in_text = @kw.opt_in_text
      end
    end

    # Append Neccessary Messaages
    if opt_in_text.blank?
        opt_in_text = "#{default_opt_in_message_obj.value}"
    else
        opt_in_text += " #{additional_opt_out_text.value}"
    end

    # Handle Opt In Media (If it Exists)
    sms = true
    opt_in_media_url = nil
    if !@kw.opt_in_media.nil? && !@kw.opt_in_media.blank?
        opt_in_media_url = @kw.opt_in_media.url
        sms = false
    end

    rate = helpers.sms_rate_check(opt_in_text)


    optin_blast = Blast.new(
      user_id: -1,
      organization: @kw.organization,
      active: true,
      keyword_id: @kw.id,
      keyword_name: @kw.name,
      message: opt_in_text,
      sms: sms,
      send_date_time: Time.now,
      contact_count: 1,
      cost: rate,
      rate: rate
    )

    if !optin_blast.save
      Honeybadger.notify("Error creating blast for keyword opt in | keyword: #{@kw.id} | Error: #{optin_blast.errors.full_messages}")
    else

      if sms == false
        new_blast_attachment = BlastAttachment.create(blast_id: optin_blast.id, attachment: @kw.opt_in_media)
        new_blast_attachment.save
      end

      blast_contact_relationship = BlastContactRelationship.new(blast: optin_blast, status: "Sent", contact_id: @c.id)

      if !blast_contact_relationship.save
        Honeybadger.notify("Error creating keyword optin blast contact relationship | blast: #{optin_blast.id}, contact: #{@c.id}")
      end
    end


    m = MgageMasterService.new
    m.process_message(@kw.organization, optin_blast)

    flash[:success] = "Success, you have been opted into the list"
    redirect_to keyword_optin_path(id: @kw.id)
    return
  end

  private

  def allow_iframe
    response.headers.except! 'X-Frame-Options'
  end

   # Creates a keyword subscription
   def process_keyword_subscription(keyword)
    logger.info("Processing Keyword Subscription Upgrade #{keyword}")
    # Commonly User Models
    current_organization = current_user.organization
    keyword_plan_id = SystemValue.find_by_key("keyword_subscription_stripe_id")
    begin
      logger.debug("Creating a new keyword subscription for the organization #{current_organization.id}")
      # Change the subscription item in Stripe
      new_keyword_subscription = Stripe::Subscription.create(
        customer: current_organization.stripe_account.stripe_id,
        metadata: {
          keyword: keyword,
        },
        items: [
          {
            plan: "#{keyword_plan_id.value}",
          }
        ]
      )
    rescue Stripe::CardError => e
      # Since it's a decline, Stripe::CardError will be caught
      body = e.json_body
      err  = body[:error]
      logger.error("Stripe Card Error Catch #{err[:message]}")
      flash[:alert] = err[:message].nil? ? "Your Card Has Failed. Please Update And Try Again." : err[:message]
      return nil
    rescue Stripe::RateLimitError => e
      # Too many requests made to the API too quickly
      body = e.json_body
      err  = body[:error]
      logger.error("Stripe Rate Limit Error Catch #{err[:message]}")
      flash[:alert] = "Our Payment Process Is A Little Busy At The Moment, Please Try Again."
      return nil
    rescue Stripe::InvalidRequestError => e
      # Invalid parameters were supplied to Stripe's API
      body = e.json_body
      err  = body[:error]
      logger.error("Stripe Invalid Parameters Error Catch #{err[:message]}")
      flash[:alert] = "Looks Like An Error On Our Part, Please Feel Free To Contact support@mobilizecomms.com."
      return nil
    rescue Stripe::AuthenticationError => e
      # Authentication with Stripe's API failed
      # (maybe you changed API keys recently)
      body = e.json_body
      err  = body[:error]
      logger.error("Stripe Authentication Error Catch #{err[:message]}")
      flash[:alert] = "Looks Like An Error On Our Part, Please Feel Free To Contact support@mobilizecomms.com."
      return nil
    rescue Stripe::APIConnectionError => e
      # Network communication with Stripe failed
      body = e.json_body
      err  = body[:error]
      logger.error("Stripe Network Error Catch #{err[:message]}")
      flash[:alert] = "Looks Like A Network Error Occured. Please Try Again."
      return nil
    rescue Stripe::StripeError => e
      # Display a very generic error to the user, and maybe send
      # yourself an email
      body = e.json_body
      err  = body[:error]
      logger.error("Stripe Generic Error Catch #{err[:message]}")
      flash[:alert] = err[:message]
      return nil
    rescue => e
      # Something else happened, completely unrelated to Stripe
      logger.error("Stripe Catch-All Error Catch #{e}")
      flash[:alert] = "Looks Like An Error On Our Part, Please Feel Free To Contact support@mobilizecomms.com."
      return nil
    end

  end

  # Removes a keyword subscription
  def remove_keyword_subscription(stripe_id)
    logger.info("Processing Keyword Subscription Removal #{stripe_id}")
    # Commonly User Models
    begin
      logger.debug("Removing keyword subscription #{stripe_id}")
      # Change the subscription item in Stripe
      canceled_subscription = Stripe::Subscription.delete(stripe_id)
    rescue Stripe::CardError => e
      # Since it's a decline, Stripe::CardError will be caught
      body = e.json_body
      err  = body[:error]
      logger.error("Stripe Card Error Catch #{err[:message]}")
      flash[:alert] = err[:message].nil? ? "Your Card Has Failed. Please Update And Try Again." : err[:message]
      return nil
    rescue Stripe::RateLimitError => e
      # Too many requests made to the API too quickly
      body = e.json_body
      err  = body[:error]
      logger.error("Stripe Rate Limit Error Catch #{err[:message]}")
      flash[:alert] = "Our Payment Process Is A Little Busy At The Moment, Please Try Again."
      return nil
    rescue Stripe::InvalidRequestError => e
      # Invalid parameters were supplied to Stripe's API
      body = e.json_body
      err  = body[:error]
      logger.error("Stripe Invalid Parameters Error Catch #{err[:message]}")
      flash[:alert] = "Looks Like An Error On Our Part, Please Feel Free To Contact support@mobilizecomms.com."
      return nil
    rescue Stripe::AuthenticationError => e
      # Authentication with Stripe's API failed
      # (maybe you changed API keys recently)
      body = e.json_body
      err  = body[:error]
      logger.error("Stripe Authentication Error Catch #{err[:message]}")
      flash[:alert] = "Looks Like An Error On Our Part, Please Feel Free To Contact support@mobilizecomms.com."
      return nil
    rescue Stripe::APIConnectionError => e
      # Network communication with Stripe failed
      body = e.json_body
      err  = body[:error]
      logger.error("Stripe Network Error Catch #{err[:message]}")
      flash[:alert] = "Looks Like A Network Error Occured. Please Try Again."
      return nil
    rescue Stripe::StripeError => e
      # Display a very generic error to the user, and maybe send
      # yourself an email
      body = e.json_body
      err  = body[:error]
      logger.error("Stripe Generic Error Catch #{err[:message]}")
      flash[:alert] = err[:message]
      return nil
    rescue => e
      # Something else happened, completely unrelated to Stripe
      logger.error("Stripe Catch-All Error Catch #{e}")
      flash[:alert] = "Looks Like An Error On Our Part, Please Feel Free To Contact support@mobilizecomms.com."
      return nil
    end

  end

end
