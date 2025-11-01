require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:one)
    @user = users(:one)
  end

  test "should get index" do
    get account_users_url(@account)
    assert_response :success
  end

  test "should get new" do
    get new_account_user_url(@account)
    assert_response :success
  end

  test "should create user" do
    assert_difference("User.count") do
      post account_users_url(@account), params: { user: { name: "New User", email: "newuser@test.com" } }
    end

    assert_redirected_to account_users_url(@account)
  end

  test "should not create user without email" do
    assert_no_difference("User.count") do
      post account_users_url(@account), params: { user: { name: "New User", email: "" } }
    end

    assert_response :unprocessable_entity
  end
end
