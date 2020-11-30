class ReportsController < ApplicationController
  before_action :authenticate_user!

  def overview

  end

  def create_blast_report

    ReportExportJob.perform_async("blast_report", params[:month], params[:year], current_user.id)

    flash["success"] = "Your report is being created now. We will email the report once we finish."
    
    redirect_to reports_overview_path
  end

end
