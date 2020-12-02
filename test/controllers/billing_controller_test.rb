require 'test_helper'

class BillingControllerTest < ActionDispatch::IntegrationTest
  test "should get overview" do
    get billing_overview_url
    assert_response :success
  end

end
