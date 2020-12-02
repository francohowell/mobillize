class DashboardsController < ApplicationController

  before_action :authenticate_user!

  def dashboard
    @terms_need_displayed = !current_user.terms_up_to_date?
    if @terms_need_displayed
      @recent_term = Term.last
    end

    t = Time.now
    month_start = t.at_beginning_of_month
    month_end = t.at_end_of_month
    @organization = current_user.organization

    @blasts = @organization.blasts.where("send_date_time BETWEEN ? AND ?", month_start, month_end).order("send_date_time DESC")
    @long_code = @organization.phone_numbers.where(long_code: true).first

    # Messages
    @messages_used = 0
    # for b in @blasts
    #   @messages_used += b.contact_count * b.rate
    # end

    @messages_allocated = @organization.annual_credits
    @messages_remaining = (@messages_allocated -  @messages_used) >= 0 ? (@messages_allocated -  @messages_used) : 0
    @message_utilization = (@messages_used / @messages_allocated) * 100
    

    # Most Recents
    @recent_blasts = @blasts.where("send_date_time <= ? AND user_id != ?", t, 0).order("send_date_time DESC").limit(4)
    @recent_responses = Response.where("keyword IN (?) AND created_at BETWEEN ? AND ?", @organization.keyword_names, month_start, month_end ).where.not(opt_out: true).order("created_at DESC").limit(5)
    @upcoming_blasts = @blasts.where("send_date_time > ?", t).order("send_date_time DESC").limit(4)

    # Contacts
    @contacts_count = @organization.contacts.count
    @keywords_count = @organization.keywords.count
    @new_contacts_count = @organization.contacts.where("created_at BETWEEN ? AND ?", month_start, month_end).count
    @opt_out_count = Response.where("keyword IN (?) AND opt_out = ? AND created_at BETWEEN ? AND ?", @organization.keyword_names, true, month_start, month_end).count

  end

end
