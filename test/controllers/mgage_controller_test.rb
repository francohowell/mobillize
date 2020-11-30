require 'test_helper'

class MgageControllerTest < ActionDispatch::IntegrationTest
  test "should get mgage_dr" do
    get mgage_mgage_dr_url
    assert_response :success
  end

  test "should get mgage_mo" do
    get mgage_mgage_mo_url
    assert_response :success
  end

end
