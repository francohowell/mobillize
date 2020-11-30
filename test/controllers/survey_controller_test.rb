require 'test_helper'

class SurveyControllerTest < ActionDispatch::IntegrationTest
  test "should get overview" do
    get survey_overview_url
    assert_response :success
  end

end
