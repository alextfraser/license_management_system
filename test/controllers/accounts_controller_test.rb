require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:one)
  end

  test "should get index" do
    get accounts_url
    assert_response :success
  end

  test "should get show" do
    get account_url(@account)
    assert_response :success
  end

  test "should get new" do
    get new_account_url
    assert_response :success
  end

  test "should create account" do
    assert_difference("Account.count") do
      post accounts_url, params: { account: { name: "New Account" } }
    end

    assert_redirected_to account_url(Account.last)
  end

  test "should not create account without name" do
    assert_no_difference("Account.count") do
      post accounts_url, params: { account: { name: "" } }
    end

    assert_response :unprocessable_entity
  end
end
