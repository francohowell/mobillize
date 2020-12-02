class PagesController < ApplicationController
  def search_results
  end

  def internal_server_error
    respond_to do |format|
      format.html { render status: 500,  :layout => "empty" }
      format.json { render json: { error: "Internal server error" }, status: 500 }
    end
  end

  def empty_page
  end

  def not_found_error
    respond_to do |format|
      format.html { render status: 404, :layout => "empty" }
      format.json { render json: { error: "Resource not found" }, status: 404 }
    end
  end

end
