require 'test_helper'

class ContactControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get contact_new_url
    assert_response :success
  end

  test "should get overview" do
    get contact_overview_url
    assert_response :success
  end

end
