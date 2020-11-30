require 'test_helper'

class WebhookEndpointControllerTest < ActionDispatch::IntegrationTest
  test "should get stripe_endpoint" do
    get webhook_endpoint_stripe_endpoint_url
    assert_response :success
  end

end
