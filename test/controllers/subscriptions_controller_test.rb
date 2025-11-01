require "test_helper"

class SubscriptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:one)
    @subscription = subscriptions(:one)
  end

  test "should get index" do
    get account_subscriptions_url(@account)
    assert_response :success
  end

  test "should get new" do
    get new_account_subscription_url(@account)
    assert_response :success
  end

  test "should create subscription" do
    product = products(:two)  # Use a product without subscription yet

    assert_difference("Subscription.count") do
      post account_subscriptions_url(@account), params: {
        subscription: {
          product_id: product.id,
          number_of_licenses: 5,
          issued_at: Time.current,
          expires_at: 1.year.from_now
        }
      }
    end

    assert_redirected_to account_subscriptions_url(@account)
  end

  test "should not create subscription without number_of_licenses" do
    product = Product.create!(name: "Test Product")

    assert_no_difference("Subscription.count") do
      post account_subscriptions_url(@account), params: {
        subscription: {
          product_id: product.id,
          number_of_licenses: nil,
          issued_at: Time.current,
          expires_at: 1.year.from_now
        }
      }
    end

    assert_response :unprocessable_entity
  end
end
