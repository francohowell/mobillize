require 'test_helper'

class KeywordControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get keyword_new_url
    assert_response :success
  end

  test "should get show" do
    get keyword_show_url
    assert_response :success
  end

  test "should get create" do
    get keyword_create_url
    assert_response :success
  end

  test "should get edit" do
    get keyword_edit_url
    assert_response :success
  end

  test "should get update" do
    get keyword_update_url
    assert_response :success
  end

  test "should get delete" do
    get keyword_delete_url
    assert_response :success
  end

end
