require 'test_helper'

class PlansControllerTest < ActionDispatch::IntegrationTest
  test "should get overview" do
    get plans_overview_url
    assert_response :success
  end

end
