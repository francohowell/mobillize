require 'test_helper'

class OrganizationControllerTest < ActionDispatch::IntegrationTest
  test "should get edit" do
    get organization_edit_url
    assert_response :success
  end

end
