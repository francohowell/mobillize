require 'test_helper'

class InboxControllerTest < ActionDispatch::IntegrationTest
  test "should get overview" do
    get inbox_overview_url
    assert_response :success
  end

  test "should get feed" do
    get inbox_feed_url
    assert_response :success
  end

end
