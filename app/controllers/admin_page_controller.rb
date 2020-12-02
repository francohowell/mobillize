class AdminPageController < ApplicationController
  before_action :authenticate_admin!
  skip_before_action :notification_check


  include Pagy::Backend
  include PaymentProcessor
  layout 'admin_application'


  ### --- Overviews --- ###

  def monthly_overview

    # Filtering Based Upon The Month
    if params[:month] && params[:year]
      date = DateTime.new(params[:year].to_i, Date::MONTHNAMES.index(params[:month]), 1)
      month_start = date.at_beginning_of_month
      month_end = date.at_end_of_month
      @month = params[:month]
      @year = params[:year]
    else
      today = DateTime.now
      month_start = today.at_beginning_of_month
      month_end = today.at_end_of_month
      @month = Date::MONTHNAMES[today.month]
      @year = today.year
    end

    # Previous Month
    previous_month_start = month_start - 1.month
    previous_month_end = previous_month_start.at_end_of_month

    ## Accounts ##
    @total_accounts_count = Organization.where(active: true).count
    @new_accounts_count = Organization.where("created_at BETWEEN ? AND ?", month_start, month_end).count
    @last_month_new_accounts_count = Organization.where("created_at BETWEEN ? AND ?", previous_month_start, previous_month_end).count
    @difference_new_accounts = ((@new_accounts_count - @last_month_new_accounts_count) / (@last_month_new_accounts_count > 0 ? @last_month_new_accounts_count : 1)) * 100.0
    @deactivated_acccounts_total = Organization.where("inactive_date BETWEEN ? AND ?", month_start, month_end).count
    @last_monthdeactivated_acccounts_total = Organization.where("inactive_date BETWEEN ? AND ?", previous_month_start, previous_month_end).count
    @difference_deactivated_accounts = ((@deactivated_acccounts_total - @last_monthdeactivated_acccounts_total) / (@last_monthdeactivated_acccounts_total > 0 ? @last_monthdeactivated_acccounts_total : 1)) * 100.0
    @total_deactivated_accounts_count = Organization.where(active: false).count
    @pagy_new_accounts, @new_accounts = pagy(Organization.where("created_at BETWEEN ? AND ?", month_start, month_end).order("created_at DESC"))

    ## Keywords ##
    @keyword_count = Keyword.all.count
    @keyword_subscribed_count = Keyword.where.not(stripe_id: nil).count
    @keyword_new_subscribed_count = Keyword.where('created_at BETWEEN ? AND ?', month_start, month_end).where.not(stripe_id: nil).count
    @last_month_keyword_new_subscribed_count =  Keyword.where('created_at BETWEEN ? AND ?', previous_month_start, previous_month_end).where.not(stripe_id: nil).count
    @difference_keyword_subscribed = ((@keyword_new_subscribed_count - @last_month_keyword_new_subscribed_count) / (@last_month_keyword_new_subscribed_count > 0 ? @last_month_keyword_new_subscribed_count : 1)) * 100.0

    ## Short Code ##
    days_in_month = Time.days_in_month(Date::MONTHNAMES.index(@month), @year)
    @messages_by_day = Array.new
    @responses_by_day = Array.new
    @total_short_code_by_day = Array.new
    @days = Array.new
    @sms_count = 0
    @mms_count = 0
    @blast_count = 0
    @blast_average_rate = 0
    @blast_contact_average = 0
    for i in 1..days_in_month
      day_usage = 0

      @days.push(i)
      if i == 1
        day_date = month_start
      else
        day_date = month_start + i.days
      end

      day_blasts = Blast.where("send_date_time BETWEEN ? AND ?", day_date.beginning_of_day, day_date.end_of_day)
      for blast in day_blasts
        day_usage += blast.contact_count * blast.rate
      end
      @messages_by_day.push(day_usage)

      day_responses = Response.where("created_at BETWEEN ? AND ?", day_date.beginning_of_day, day_date.end_of_day)
      @responses_by_day.push(day_responses.count)

      @total_short_code_by_day.push(day_usage + day_responses.count)

      @sms_count += day_blasts.where(sms: true).count
      @mms_count += day_blasts.where(sms: false).count

      @blast_count += day_blasts.count
      @blast_average_rate += day_blasts.pluck(:rate).inject(0, :+)
      @blast_contact_average += day_blasts.pluck(:contact_count).inject(0, :+)

    end
    if @blast_count > 0
      @blast_average_rate = @blast_average_rate/@blast_count
      @blast_contact_average = @blast_contact_average/@blast_count
    else
      @blast_average_rate = 0
      @blast_contact_average = 0
    end
    @pagy_new_blasts, @new_blasts = pagy(Blast.where("send_date_time BETWEEN ? AND ?", month_start.beginning_of_day, month_end.end_of_day).where.not("user_id = ?", 0).order("send_date_time DESC"))


    ## Income ##
    @income = 0.0
    for plan in Plan.all
      if plan.name == "CheckPlan"
        for org in plan.organizations.where(active: true)
          org_blasts = org.blasts.where("send_date_time BETWEEN ? AND ?", month_start.beginning_of_day, month_end.end_of_day)
          for b in org_blasts
            @income += b.contact_count * b.rate * 0.035 # Check Plan Rate
          end
        end
      else
        @income += plan.organizations.count * plan.monthly_price
      end
    end
    # Blasts That Are PayGo
    paygo_blasts = Blast.where("send_date_time BETWEEN ? AND ?", month_start.beginning_of_day, month_end.end_of_day).where.not(stripe_id: nil)
    for blast in paygo_blasts
      @income += blast.cost
    end
    # Keywords
    @income += Keyword.where.not(stripe_id: nil).count * 25

  end

  def yearly_overview
    # Filtering Based Upon The Month
    if params[:year]
      date = DateTime.new(params[:year].to_i, 1, 1)
      year_start = date.beginning_of_day
      year_end = date.end_of_year.end_of_day
      @year = params[:year]
    else
      today = DateTime.now
      year_start = today.beginning_of_year.beginning_of_day
      year_end = today.end_of_year
      @year = today.year
    end

    ## Accounts ##
    @new_accounts_by_month = Array.new
    @deactivated_accounts_by_month = Array.new
    @total_accounts_by_month = Array.new
    for i in 1..12
      month_start = DateTime.new(@year, i, 1).beginning_of_day
      month_end = month_start.end_of_month.end_of_day
      new_count = Organization.where("active = true AND created_at BETWEEN ? AND ?", month_start, month_end).count
      @new_accounts_by_month.push(new_count)
      dead_count = Organization.where("active = false AND inactive_date BETWEEN ? AND ?", month_start, month_end).count
      @deactivated_accounts_by_month.push(dead_count)
      @total_accounts_by_month.push(new_count + dead_count)
    end
    @new_account_total = @new_accounts_by_month.inject(0, :+)
    @deactivated_account_total = @deactivated_accounts_by_month.inject(0, :+)
    @account_total = @new_account_total + @deactivated_account_total

    ## Keywords ##
    @new_keywords_by_month = Array.new
    @new_subscribed_keywords_by_month = Array.new
    @total_keywords_by_month = Array.new
    for i in 1..12
      month_start = DateTime.new(@year, i, 1).beginning_of_day
      month_end = month_start.end_of_month.end_of_day
      new_count = Keyword.where("stripe_id IS NULL AND created_at BETWEEN ? AND ?", month_start, month_end).count
      @new_keywords_by_month.push(new_count)
      subscribed_count = Keyword.where("stripe_id IS NOT NULL AND created_at BETWEEN ? AND ?", month_start, month_end).count
      @new_subscribed_keywords_by_month.push(subscribed_count)
      @total_keywords_by_month.push(new_count + subscribed_count)
    end
    @new_keyword_total = @new_accounts_by_month.inject(0, :+)
    @new_subscribed_keyword_total = @new_subscribed_keywords_by_month.inject(0, :+)
    @keyword_total = @total_keywords_by_month.inject(0, :+)

    ## Short Code ##
    @messages_by_month = Array.new
    @responses_by_month = Array.new
    @total_messages_by_month = Array.new
    @blast_count = 0
    @blast_avg_rate = 0
    @blast_avg_contact_count = 0
    @sms_count = 0
    @mms_count = 0
    for i in 1..12
      month_start = DateTime.new(@year, i, 1).beginning_of_day
      month_end = month_start.end_of_month.end_of_day
      blast_count = 0
      months_blasts = Blast.select(:rate, :contact_count, :sms).where("send_date_time BETWEEN ? AND ?", month_start, month_end)
      for blast in months_blasts
        @blast_count += 1
        @blast_avg_rate += blast.rate
        @blast_avg_contact_count += blast.contact_count
        if blast.sms
          @sms_count += blast.contact_count * blast.rate
        else
          @mms_count += blast.contact_count * blast.rate
        end
        blast_count += blast.contact_count * blast.rate
      end
      @messages_by_month.push(blast_count)
      response_count = Response.where("created_at BETWEEN ? AND ?", month_start, month_end).count
      @responses_by_month.push(response_count)
      @total_messages_by_month.push(blast_count + response_count)
    end
    @message_amount = @messages_by_month.inject(0, :+)
    @response_amount = @responses_by_month.inject(0, :+)
    @blast_avg_rate = @blast_avg_rate / @blast_count
    @blast_avg_contact_count = @blast_avg_contact_count / @blast_count


    ## Income ##
    @income_by_month = Array.new
    @refund_by_month = Array.new
    @total_by_month = Array.new
    for i in 1..12
      month_start = DateTime.new(@year, i, 1).beginning_of_day
      month_end = month_start.end_of_month.end_of_day
      results = charges_made(month_start, month_end)
      if results["success"]
        income_cal = 0
        for result in results["data"]
          income_cal += (result["amount"]/100)
        end
        @income_by_month.push(income_cal)
      end
      response_results = refunds_made(month_start, month_end)
      if response_results["success"]
        resp_income_cal = 0
        for result in response_results["data"]
          resp_income_cal += (result["amount"]/100)
        end
        @refund_by_month.push(resp_income_cal)
        @total_by_month.push(income_cal - resp_income_cal)
      end
    end
    @total_charged = @income_by_month.inject(0, :+)
    @total_refunded = @refund_by_month.inject(0, :+)
    @total_net = @total_charged - @total_refunded

  end

  ### --- Opt Outs --- ###

  def opt_out_queue
    @pagy_opt_outs, @opt_outs = pagy(Response.where(possible_opt_out: true, opt_out: false).order("created_at DESC"))
  end

  def update_opt_out
    response = Response.find_by_id(params[:id])
    if !response
      flash[:alert] = "Could not find the response to update."
      redirect_to admin_page_opt_out_queue_path
    end
    update_state = params[:status]
    if update_state == "clear"
      response.possible_opt_out = false
      if !response.save
        flash[:alert] = "Could not update the response. #{response.errors.full_messages}"
        redirect_to admin_page_opt_out_queue_path
      else
        flash[:success] = "Response updated!"
        redirect_to admin_page_opt_out_queue_path
      end
    else
      # This is an opt-out
      response.possible_opt_out = false
      response.opt_out = true
      if !response.save
        flash[:alert] = "Could not update the response. #{response.errors.full_messages}"
        redirect_to admin_page_opt_out_queue_path
      else
        # Process The Opt Out System Wide
        contacts = Contact.where(cell_phone: response.cell_phone)
        for c in contacts
          c.active = false
          if !c.save
            flash[:alert] = "Could not mark all records of the response as an opt out. Please take not of the cell phone number and send to the dev team. #{c.errors.full_messages}"
            redirect_to admin_page_opt_out_queue_path
          end
        end

        mgageService = MgageMasterService.new()
        mgageService.send_opt_out_message(response.cell_phone, "94502")

        flash[:success] = "Response updated!"
        redirect_to admin_page_opt_out_queue_path
      end
    end
  end

  ### --- System Notifications --- ###
  def system_notifications
    @notif = Notification.new
    @pagy_notif, @notifications = pagy(Notification.all.order("start_date DESC"))
  end

  def create_notifcation
    title = params[:notification][:title]
    message = params[:notification][:description]

    # Format The Date Times
    start_time = params[:notification][:start_date]
    start_time = Date.strptime(start_time, '%m/%d/%Y')

    end_time = params[:notification][:end_date]
    end_time = Date.strptime(end_time, '%m/%d/%Y')

    new_notification = Notification.new(title: title, description: message, start_date: start_time, end_date: end_time)
    if !new_notification.save
      flash["alert"] = "Failed to create notification: #{new_notification.errors.full_messages}."
    else
      flash["success"] = "Notification created."
    end

    redirect_to admin_page_system_notifications_path
  end

  def delete_notification
    notification_id = params[:notification_id]
    notification = Notification.find_by_id(notification_id)

    if !notification
      flash["alert"] = "Could not find the notification to delete."
      redirect_to admin_page_system_notifications_path
      return
    end

    if !notification.destroy
      flash["alert"] = "Could not delete the notification contact Dev team."
    else
      flash["success"] = "Notification deleted."
    end

    redirect_to admin_page_system_notifications_path
    return
  end

  def edit_notification
    notification_id = params[:notification_id]
    @notif = Notification.find_by_id(notification_id)

    if !@notif
      flash["alert"] = "Could not find the notification to delete."
      redirect_to admin_page_system_notifications_path
      return
    end

    @notif.start_date = @notif.start_date.strftime('%m/%d/%Y')
    @notif.end_date = @notif.end_date.strftime('%m/%d/%Y')
  end

  def update_notification

    notification_id = params[:notification_id]
    @notif = Notification.find_by_id(notification_id)

    if !@notif
      flash["alert"] = "Could not find the notification to delete."
      redirect_to admin_page_system_notifications_path
      return
    end

    title = params[:notification][:title]
    message = params[:notification][:description]

    # Format The Date Times
    start_time = params[:notification][:start_date]
    start_time = Date.strptime(start_time, '%m/%d/%Y')

    end_time = params[:notification][:end_date]
    end_time = Date.strptime(end_time, '%m/%d/%Y')

    @notif.title = title
    @notif.description = message
    @notif.start_date = start_time
    @notif.end_date = end_time

    if !@notif.save
      flash["alert"] = "Failed to create notification: #{new_notification.errors.full_messages}."
    else
      flash["success"] = "Notification Updated."
    end

    redirect_to admin_page_system_notifications_path
  end

  ### --- Organizations --- ###

  def organizations
    if params[:search]
      @pagy_orgs, @orgs = pagy(Organization.where("name ILIKE :search", search: "%#{params[:search]}%"), items: 25)
    else
      @pagy_orgs, @orgs = pagy(Organization.all.order(:name))
    end
  end

  def manage_organization
    organization_id = params[:organization_id]
    @organization = Organization.find_by_id(organization_id)

    if !@organization
      flash["alert"] = "Organization with id: #{organization_id} cannot be found."
      redirect_to admin_page_organizations_path
      return
    end

    @active_subscriptions = Array.new
    @pastdue_subscriptions = Array.new
    @canceled_subscriptions = Array.new
    @invoices = Array.new
    @charges = Array.new

    # Stripe Details
    if @organization.stripe_account

      response_results = customer_subscriptions(@organization.stripe_account.stripe_id, "active")
      puts "ACTIVE SUB-----> #{response_results}"
      if response_results["success"]
        for result in response_results["data"]
          data_hash = Hash.new
          data_hash["created_at"] = result["created"]
          data_hash["collection_type"] = result["collection_method"]
          data_hash["due_date"] = result["current_period_end"]
          data_hash["last_invoice"] = "https://dashboard.stripe.com/invoices/#{result["latest_invoice"]}"
          data_hash["plan_amount"] = result["plan"]["amount"]
          plan_id = result["plan"]["id"]
          possible_plan = Plan.where("stripe_id = ? OR annual_stripe_id = ?", plan_id, plan_id).limit(1)
          if !possible_plan.empty?
            data_hash["plan_name"] = possible_plan.first.name
          else
            data_hash["plan_name"] = "Not Found"
          end
          data_hash["plan_interval"] = result["plan"]["interval"]
          @active_subscriptions.push(data_hash)
        end
      end

      response_past_due_results = customer_subscriptions(@organization.stripe_account.stripe_id, "past_due")
      puts "Past Due SUB-----> #{response_past_due_results}"
      if response_past_due_results["success"]
        if !response_past_due_results["data"].blank?
          for result in response_past_due_results["data"]
            data_hash = Hash.new
            data_hash["created_at"] = result["created"]
            data_hash["collection_type"] = result["collection_method"]
            data_hash["due_date"] = result["current_period_end"]
            data_hash["last_invoice"] = "https://dashboard.stripe.com/invoices/#{result["latest_invoice"]}"
            data_hash["plan_amount"] = result["plan"]["amount"]
            plan_id = result["plan"]["id"]
            possible_plan = Plan.where("stripe_id = ? OR annual_stripe_id = ?", plan_id, plan_id).limit(1)
            if !possible_plan.empty?
              data_hash["plan_name"] = possible_plan.first.name
            else
              data_hash["plan_name"] = "Not Found"
            end
            data_hash["plan_interval"] = result["plan"]["interval"]
            @pastdue_subscriptions.push(data_hash)
          end
        end
      end

      response_canceled_results = customer_subscriptions(@organization.stripe_account.stripe_id, "canceled")
      puts "Past Canceled-----> #{response_canceled_results}"
      if response_canceled_results["success"]
        if !response_canceled_results["data"].blank?
          for result in response_canceled_results["data"]
            data_hash = Hash.new
            data_hash["created_at"] = result["created"]
            data_hash["collection_type"] = result["collection_method"]
            data_hash["canceled_date"] = result["cancel_at"]
            data_hash["last_invoice"] = "https://dashboard.stripe.com/invoices/#{result["latest_invoice"]}"
            data_hash["plan_amount"] = result["plan"]["amount"]
            plan_id = result["plan"]["id"]
            possible_plan = Plan.where("stripe_id = ? OR annual_stripe_id = ?", plan_id, plan_id).limit(1)
            if !possible_plan.empty?
              data_hash["plan_name"] = possible_plan.first.name
            else
              data_hash["plan_name"] = "Not Found"
            end
            data_hash["plan_interval"] = result["plan"]["interval"]
            @pastdue_subscriptions.push(data_hash)
          end
        end
      end

      response_invoices_results = customer_invoices(@organization.stripe_account.stripe_id)
      puts "Invoices-----> #{response_invoices_results}"
      if response_invoices_results["success"]
        if !response_invoices_results["data"].blank?
          for result in response_invoices_results["data"]
            data_hash = Hash.new
            data_hash["created_at"] = result["created"]
            data_hash["collection_type"] = result["collection_method"]
            data_hash["email"] = result["customer_email"]
            data_hash["due_date"] = result["due_date"]
            data_hash["balance"] = result["ending_balance"]
            data_hash["invoice_url"] = result["hosted_invoice_url"]
            data_hash["invoice_pdf"] = result["invoice_pdf"]
            data_hash["status"] = result["status"]
            data_hash["total"] = result["total"]
            @invoices.push(data_hash)
          end
        end
      end

      response_charges_results = customer_charges(@organization.stripe_account.stripe_id)
      puts "Invoices-----> #{response_charges_results}"
      if response_charges_results["success"]
        if !response_charges_results["data"].blank?
          for result in response_charges_results["data"]
            data_hash = Hash.new
            data_hash["created_at"] = result["created"]
            data_hash["amount"] = result["amount"]
            data_hash["disputed"] = result["disputed"]
            data_hash["invoice"] = result["invoice"]
            data_hash["receipt_url"] = result["receipt_url"]
            data_hash["refunded"] = result["refunded"]
            data_hash["status"] = result["status"]
            @charges.push(data_hash)
          end
        end
      end


    end

    @recent_blasts = @organization.blasts.where.not("user_id = ?", 0).order("send_date_time DESC").limit(25)


  end

  def update_notes
    notes = params[:notes]
    organization_id = params[:organization_id]
    @organization = Organization.find_by_id(organization_id)
    if !@organization
      flash["alert"] = "Organization with id: #{organization_id} cannot be found."
      redirect_to admin_page_organizations_path
      return
    end

    @organization.notes = notes
    if !@organization.save
      flash["alert"] = "Failed to save the notes: #{@organization.errors.full_messages}."
    else
      flash["success"] = "Notes Updated!"
    end

    redirect_to admin_page_manage_organization_path(organization_id: organization_id)
    return

  end

  def deactivate_organization
    organization_id = params[:organization_id]
    @organization = Organization.find_by_id(organization_id)
    if !@organization
      flash["alert"] = "Organization with id: #{organization_id} cannot be found."
      redirect_to admin_page_organizations_path
      return
    end

    # Remove Keyword Subscriptions + Keywords
    keywords = @organization.keywords
    for keyword in keywords
      if !keyword.stripe_id.nil? && !keyword.stripe_id.blank?

        result = cancel_subscription(keyword.stripe_id)
        if !result
          redirect_to admin_page_organizations_path
          return
        end
      end

      if !keyword.destroy
        flash["alert"] = "Keyword #{keyword.id} #{keyword.name} could not be removed from the account. Please contact dev team."
        redirect_to admin_page_organizations_path
        return
      end

    end

    # Mark Inactive
    deactivated_plan = Plan.find_by_name("Deactivated")
    @organization.active = false
    @organization.plan = deactivated_plan
    # @organizaton.keywords.destroy_all or delete_all this would get rid of the keywords tied to the organization should we warn them?

    if !@organization.save
      flash["alert"] = "Failed to mark organization inactive however subscriptions where removed. Please contact dev team."
      redirect_to admin_page_organizations_path
      return
    end

    flash["success"] = "Organization has been deactivated!"
    redirect_to admin_page_organizations_path
    return

  end

  ### --- Reports --- ###

  def reports
    # Filtering Based Upon The Month
    if params[:month] && params[:year]
      date = DateTime.new(params[:year].to_i, Date::MONTHNAMES.index(params[:month]), 1)
      month_start = date.at_beginning_of_month
      month_end = date.at_end_of_month
      @month = params[:month]
      @year = params[:year]
    else
      today = DateTime.now
      month_start = today.at_beginning_of_month
      month_end = today.at_end_of_month
      @month = Date::MONTHNAMES[today.month]
      @year = today.year
    end

    @organization_select = Organization.select(:id, :name).where(active: true).order("name").pluck(:name, :id)
  end

  def usage_report
    if params[:month] && params[:year]
      date = DateTime.new(params[:year].to_i, Date::MONTHNAMES.index(params[:month]), 1)
      month_start = date.at_beginning_of_month
      month_end = date.at_end_of_month
      @month = params[:month]
      @year = params[:year]
    else
      today = DateTime.now
      month_start = today.at_beginning_of_month
      month_end = today.at_end_of_month
      @month = Date::MONTHNAMES[today.month]
      @year = today.year
    end
    @blasts_this_month = Blast.where("send_date_time BETWEEN ? AND ?", month_start, month_end)

    report = CSV.generate do |csv|
      names = ["Id", "Organization", "Active", "Plan", "Plan Messages", "Plan Keywords", "Subscribed Keywords", "Messages Out", "Messages In", "Keyword Count", "Stripe Account", "Plan Start Date", "User", "User Email", "User Phone", "Notes"]
      csv << names
      Organization.all.each do |org|
        sent_count = 0
        for b in org.blasts.where("send_date_time BETWEEN ? AND ?", month_start, month_end)
          sent_count += b.contact_count * b.rate
        end
        resp = Response.where("keyword IN (?) AND created_at BETWEEN ? AND ?", org.keyword_names, month_start, month_end).count
        plan = org.plan
        stripe = "NONE"
        if org.stripe_account
          stripe = org.stripe_account.stripe_id
        end
        subscribed = org.keywords.where.not(stripe_id: nil).count
        user = org.users.last
        if user
          row = [org.id, org.name, org.active, plan.name, plan.messages_included, plan.keywords_included, subscribed, sent_count, resp, org.keywords.count, stripe, org.plan_start_date, user.name, user.email, user.cell_phone, org.notes]
        else
          row = [org.id, org.name, org.active, plan.name, plan.messages_included, plan.keywords_included, subscribed, sent_count, resp, org.keywords.count, stripe, org.plan_start_date, "No User", "No User", "No User", org.notes]
        end
        csv << row
      end
    end

    send_data report, filename: "CustomerUsage-#{month_start.month}-#{month_start.year}.csv"

  end

  def customer_usage_report
    if params[:month] && params[:year]
      date = DateTime.new(params[:year].to_i, Date::MONTHNAMES.index(params[:month]), 1)
      month_start = date.at_beginning_of_month
      month_end = date.at_end_of_month
      @month = params[:month]
      @year = params[:year]
    else
      today = DateTime.now
      month_start = today.at_beginning_of_month
      month_end = today.at_end_of_month
      @month = Date::MONTHNAMES[today.month]
      @year = today.year
    end

    organization_id = params[:organization_id]
    organization = Organization.find_by_id(organization_id)

    report = CSV.generate do |csv|
      names = ["Id", "Organization", "Active", "Plan", "Plan Messages", "Plan Keywords", "Subscribed Keywords", "Messages Out", "Messages In", "Keyword Count", "Stripe Account", "Plan Start Date", "User", "User Email", "User Phone", "Notes"]
      csv << names
      sent_count = 0
      for b in organization.blasts.where("send_date_time BETWEEN ? AND ?", month_start, month_end)
        sent_count += b.contact_count * b.rate
      end
      resp = Response.where("keyword IN (?) AND created_at BETWEEN ? AND ?", organization.keyword_names, month_start, month_end).count
      plan = organization.plan
      stripe = "NONE"
      if organization.stripe_account
        stripe = organization.stripe_account.stripe_id
      end
      subscribed = organization.keywords.where.not(stripe_id: nil).count
      user = organization.users.last
      if user
        row = [organization.id, organization.name, organization.active, plan.name, plan.messages_included, plan.keywords_included, subscribed, sent_count, resp, organization.keywords.count, stripe, organization.plan_start_date, user.name, user.email, user.cell_phone, organization.notes]
      else
        row = [organization.id, organization.name, organization.active, plan.name, plan.messages_included, plan.keywords_included, subscribed, sent_count, resp, organization.keywords.count, stripe, organization.plan_start_date, "No User", "No User", "No User", organization.notes]
      end
      csv << row
    end

    send_data report, filename: "#{organization.name}-#{organization.id}-Usage-#{month_start.month}-#{month_start.year}.csv"

  end

  def customer_blast_report
    if params[:month] && params[:year]
      date = DateTime.new(params[:year].to_i, Date::MONTHNAMES.index(params[:month]), 1)
      month_start = date.at_beginning_of_month
      month_end = date.at_end_of_month
      @month = params[:month]
      @year = params[:year]
    else
      today = DateTime.now
      month_start = today.at_beginning_of_month
      month_end = today.at_end_of_month
      @month = Date::MONTHNAMES[today.month]
      @year = today.year
    end

    organization_id = params[:organization_id]
    organization = Organization.find_by_id(organization_id)

    report = CSV.generate do |csv|
      names = ["Id", "Organization", "Send Date Time", "Keyword", "Message", "Contact Count", "Rate", "Cost", "SMS", "Groups", "Repeat"]
      csv << names
      sent_count = 0
      for b in organization.blasts.where("send_date_time BETWEEN ? AND ?", month_start, month_end).order("send_date_time DESC")
        groups = b.groups.pluck(:name).join(" | ")
        csv << [b.id, organization.id, b.send_date_time.in_time_zone(organization.timezone), b.keyword_name, b.outgoing_message, b.contact_count, b.rate, b.cost, b.sms ? "True" : "False", groups, b.repeat]
      end
    end

    send_data report, filename: "#{organization.name}-#{organization.id}-Blasts-#{month_start.month}-#{month_start.year}.csv"

  end

  def new_account_report
    if params[:month] && params[:year]
      date = DateTime.new(params[:year].to_i, Date::MONTHNAMES.index(params[:month]), 1)
      month_start = date.at_beginning_of_month
      month_end = date.at_end_of_month
      @month = params[:month]
      @year = params[:year]
    else
      today = DateTime.now
      month_start = today.at_beginning_of_month
      month_end = today.at_end_of_month
      @month = Date::MONTHNAMES[today.month]
      @year = today.year
    end

    report = CSV.generate do |csv|
      names = ["Id", "Organization", "Activated", "Created At", "City", "State", "Size", "Industry", "Timezone", "User Id", "User Name", "User Email", "User Cell Phone"]
      csv << names
      sent_count = 0

      for o in Organization.where("active = ? AND created_at BETWEEN ? AND ?", true, month_start, month_end).order("created_at DESC")
        org_users = o.users.where.not(confirmed_at: nil)
        activated = false
        if !org_users.empty?
         activated = true
        end
        first_user = o.users.first
        if !first_user
          csv << [o.id, o.name, activated, o.created_at.in_time_zone(o.timezone), o.city, o.state_providence, o.size, o.industry, o.timezone, "No User", "No User", "No User", "No User"]
        else
          csv << [o.id, o.name, activated, o.created_at.in_time_zone(o.timezone), o.city, o.state_providence, o.size, o.industry, o.timezone, first_user.id, first_user.name, first_user.email, first_user.cell_phone]

        end
      end
    end

    send_data report, filename: "New-Accounts-#{month_start.month}-#{month_start.year}.csv"

  end

  private

  def credit_card_check(number, month, year)
    detector = CreditCardValidations::Detector.new(number)
    if !detector.valid?
      flash[:alert] = "Credit Card Number Is Invalid"
      return false
    end

    # Check Credit Card Month
    if month <= 0 || month > 12
      flash[:alert] = "Expiration Month has must be 01 - 12 "
      return false
    end

    # Check Credit Card Year
    if (year + 2000) < Time.now.year
      flash[:alert] = "Expiration Year must be this or greater "
      return false
    end

    # Check Expiration
    if (year + 2000) == Time.now.year
      if month <= Time.now.month
        flash[:alert] = "This Card Has Expired"
        return false
      end
    end

    return true
  end

  def stripe_token_create(name, number, month, year, cvc)

    begin
      # Use Stripe's library to make requests...
      Stripe::Token.create({
        card: {
          number: number,
          exp_month: month,
          exp_year: year,
          cvc: cvc,
          name: name
        },
      })
    rescue Stripe::CardError => e
      # Since it's a decline, Stripe::CardError will be caught
      body = e.json_body
      err  = body[:error]
      flash[:alert] = err[:message].nil? ? "Your Card Has Failed. Please Update And Try Again." : err[:message]
      return nil
    rescue Stripe::RateLimitError => e
      # Too many requests made to the API too quickly
      flash[:alert] = "Our Payment Process Is A Little Busy At The Moment, Please Try Again."
      return nil
    rescue Stripe::InvalidRequestError => e
      # Invalid parameters were supplied to Stripe's API
      flash[:alert] = "Looks Like An Error On Our Part, Please Feel Free To Contact support@mobilizecomms.com."
      return nil
    rescue Stripe::AuthenticationError => e
      # Authentication with Stripe's API failed
      # (maybe you changed API keys recently)
      flash[:alert] = "Looks Like An Error On Our Part, Please Feel Free To Contact support@mobilizecomms.com."
      return nil
    rescue Stripe::APIConnectionError => e
      # Network communication with Stripe failed
      flash[:alert] = "Looks Like A Network Error Occured. Please Try Again."
      return nil
    rescue Stripe::StripeError => e
      # Display a very generic error to the user, and maybe send
      # yourself an email
      body = e.json_body
      err  = body[:error]
      flash[:alert] = err[:message]
      return nil
    rescue => e
      # Something else happened, completely unrelated to Stripe
      flash[:alert] = "Looks Like An Error On Our Part, Please Feel Free To Contact support@mobilizecomms.com."
      return nil
    end
  end

  def stripe_update_payment(stripe_id, source)
    begin
      s = Stripe::Customer.update(
        stripe_id,
        {
          source: source,
        }
      )
      return s
    rescue Stripe::CardError => e
      # Since it's a decline, Stripe::CardError will be caught
      body = e.json_body
      err  = body[:error]
      flash[:alert] = err[:message].nil? ? "Your Card Has Failed. Please Update And Try Again." : err[:message]
      return nil
    rescue Stripe::RateLimitError => e
      # Too many requests made to the API too quickly
      flash[:alert] = "Our Payment Process Is A Little Busy At The Moment, Please Try Again."
      return nil
    rescue Stripe::InvalidRequestError => e
      # Invalid parameters were supplied to Stripe's API
      flash[:alert] = "Looks Like An Error On Our Part, Please Feel Free To Contact support@mobilizecomms.com."
      return nil
    rescue Stripe::AuthenticationError => e
      # Authentication with Stripe's API failed
      # (maybe you changed API keys recently)
      flash[:alert] = "Looks Like An Error On Our Part, Please Feel Free To Contact support@mobilizecomms.com."
      return nil
    rescue Stripe::APIConnectionError => e
      # Network communication with Stripe failed
      flash[:alert] = "Looks Like A Network Error Occured. Please Try Again."
      return nil
    rescue Stripe::StripeError => e
      # Display a very generic error to the user, and maybe send
      # yourself an email
      body = e.json_body
      err  = body[:error]
      flash[:alert] = err[:message]
      return nil
    rescue => e
      # Something else happened, completely unrelated to Stripe
      flash[:alert] = "Looks Like An Error On Our Part, Please Feel Free To Contact support@mobilizecomms.com."
      return nil
    end
  end

  def cancel_subscription(stripe_id)
    begin
      s = Stripe::Subscription.delete(stripe_id)
      return s
    rescue Stripe::CardError => e
      # Since it's a decline, Stripe::CardError will be caught
      body = e.json_body
      err  = body[:error]
      flash[:alert] = err[:message].nil? ? "Your Card Has Failed. Please Update And Try Again." : err[:message]
      return nil
    rescue Stripe::RateLimitError => e
      # Too many requests made to the API too quickly
      flash[:alert] = "Our Payment Process Is A Little Busy At The Moment, Please Try Again."
      return nil
    rescue Stripe::InvalidRequestError => e
      # Invalid parameters were supplied to Stripe's API
      flash[:alert] = "Looks Like An Error On Our Part, Please Feel Free To Contact support@mobilizecomms.com."
      return nil
    rescue Stripe::AuthenticationError => e
      # Authentication with Stripe's API failed
      # (maybe you changed API keys recently)
      flash[:alert] = "Looks Like An Error On Our Part, Please Feel Free To Contact support@mobilizecomms.com."
      return nil
    rescue Stripe::APIConnectionError => e
      # Network communication with Stripe failed
      flash[:alert] = "Looks Like A Network Error Occured. Please Try Again."
      return nil
    rescue Stripe::StripeError => e
      # Display a very generic error to the user, and maybe send
      # yourself an email
      body = e.json_body
      err  = body[:error]
      flash[:alert] = err[:message]
      return nil
    rescue => e
      # Something else happened, completely unrelated to Stripe
      flash[:alert] = "Looks Like An Error On Our Part, Please Feel Free To Contact support@mobilizecomms.com."
      return nil
    end
  end

end
