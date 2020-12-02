require 'test_helper'

class BlastControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get blast_new_url
    assert_response :success
  end

end
