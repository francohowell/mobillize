require 'test_helper'

class PolicyControllerTest < ActionDispatch::IntegrationTest
  test "should get terms_conditions" do
    get policy_terms_conditions_url
    assert_response :success
  end

  test "should get privacy" do
    get policy_privacy_url
    assert_response :success
  end

  test "should get spam" do
    get policy_spam_url
    assert_response :success
  end

end
