require 'test_helper'

class AdminControllerTest < ActionDispatch::IntegrationTest
  test "should get create_plan" do
    get admin_create_plan_url
    assert_response :success
  end

end
