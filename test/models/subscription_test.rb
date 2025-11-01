require "test_helper"

class SubscriptionTest < ActiveSupport::TestCase
  setup do
    @account = Account.create!(name: "Test Account")
    @product = Product.create!(name: "Test Product")
  end

  test "valid subscription with all attributes" do
    subscription = Subscription.new(
      account: @account,
      product: @product,
      number_of_licenses: 10,
      issued_at: Time.current,
      expires_at: 1.year.from_now
    )
    assert subscription.valid?
  end

  test "invalid without number_of_licenses" do
    subscription = Subscription.new(
      account: @account,
      product: @product,
      number_of_licenses: nil,
      issued_at: Time.current,
      expires_at: 1.year.from_now
    )
    assert_not subscription.valid?
    assert_includes subscription.errors[:number_of_licenses], "can't be blank"
  end

  test "invalid with zero licenses" do
    subscription = Subscription.new(
      account: @account,
      product: @product,
      number_of_licenses: 0,
      issued_at: Time.current,
      expires_at: 1.year.from_now
    )
    assert_not subscription.valid?
    assert_includes subscription.errors[:number_of_licenses], "must be greater than 0"
  end

  test "invalid with negative licenses" do
    subscription = Subscription.new(
      account: @account,
      product: @product,
      number_of_licenses: -5,
      issued_at: Time.current,
      expires_at: 1.year.from_now
    )
    assert_not subscription.valid?
    assert_includes subscription.errors[:number_of_licenses], "must be greater than 0"
  end

  test "invalid with non-integer licenses" do
    subscription = Subscription.new(
      account: @account,
      product: @product,
      number_of_licenses: 5.5,
      issued_at: Time.current,
      expires_at: 1.year.from_now
    )
    assert_not subscription.valid?
    assert_includes subscription.errors[:number_of_licenses], "must be an integer"
  end

  test "invalid without issued_at" do
    subscription = Subscription.new(
      account: @account,
      product: @product,
      number_of_licenses: 10,
      issued_at: nil,
      expires_at: 1.year.from_now
    )
    assert_not subscription.valid?
    assert_includes subscription.errors[:issued_at], "can't be blank"
  end

  test "invalid without expires_at" do
    subscription = Subscription.new(
      account: @account,
      product: @product,
      number_of_licenses: 10,
      issued_at: Time.current,
      expires_at: nil
    )
    assert_not subscription.valid?
    assert_includes subscription.errors[:expires_at], "can't be blank"
  end

  test "invalid when expires_at is before issued_at" do
    subscription = Subscription.new(
      account: @account,
      product: @product,
      number_of_licenses: 10,
      issued_at: Time.current,
      expires_at: 1.day.ago
    )
    assert_not subscription.valid?
    assert_includes subscription.errors[:expires_at], "must be after issued date"
  end

  test "invalid when expires_at equals issued_at" do
    time = Time.current
    subscription = Subscription.new(
      account: @account,
      product: @product,
      number_of_licenses: 10,
      issued_at: time,
      expires_at: time
    )
    assert_not subscription.valid?
    assert_includes subscription.errors[:expires_at], "must be after issued date"
  end

  test "belongs to account" do
    subscription = Subscription.create!(
      account: @account,
      product: @product,
      number_of_licenses: 10,
      issued_at: Time.current,
      expires_at: 1.year.from_now
    )
    assert_equal @account, subscription.account
  end

  test "belongs to product" do
    subscription = Subscription.create!(
      account: @account,
      product: @product,
      number_of_licenses: 10,
      issued_at: Time.current,
      expires_at: 1.year.from_now
    )
    assert_equal @product, subscription.product
  end

  test "active scope returns only non-expired subscriptions" do
    # Create active subscription
    active_sub = Subscription.create!(
      account: @account,
      product: @product,
      number_of_licenses: 10,
      issued_at: Time.current,
      expires_at: 1.year.from_now
    )

    # Create expired subscription
    expired_sub = Subscription.create!(
      account: Account.create!(name: "Another Account"),
      product: Product.create!(name: "Another Product"),
      number_of_licenses: 5,
      issued_at: 2.years.ago,
      expires_at: 1.year.ago
    )

    active_subscriptions = Subscription.active

    assert_includes active_subscriptions, active_sub
    assert_not_includes active_subscriptions, expired_sub
  end

  test "expired? returns true for expired subscription" do
    subscription = Subscription.create!(
      account: @account,
      product: @product,
      number_of_licenses: 10,
      issued_at: 2.years.ago,
      expires_at: 1.year.ago
    )
    assert subscription.expired?
  end

  test "expired? returns false for active subscription" do
    subscription = Subscription.create!(
      account: @account,
      product: @product,
      number_of_licenses: 10,
      issued_at: Time.current,
      expires_at: 1.year.from_now
    )
    assert_not subscription.expired?
  end

  test "available_licenses returns correct count with no assignments" do
    subscription = Subscription.create!(
      account: @account,
      product: @product,
      number_of_licenses: 10,
      issued_at: Time.current,
      expires_at: 1.year.from_now
    )
    assert_equal 10, subscription.available_licenses
  end

  test "available_licenses returns correct count with some assignments" do
    subscription = Subscription.create!(
      account: @account,
      product: @product,
      number_of_licenses: 10,
      issued_at: Time.current,
      expires_at: 1.year.from_now
    )

    user1 = @account.users.create!(name: "User 1", email: "user1@test.com")
    user2 = @account.users.create!(name: "User 2", email: "user2@test.com")

    LicenseAssignment.create!(account: @account, user: user1, product: @product)
    LicenseAssignment.create!(account: @account, user: user2, product: @product)

    assert_equal 8, subscription.available_licenses
  end

  test "available_licenses returns 0 for expired subscription" do
    subscription = Subscription.create!(
      account: @account,
      product: @product,
      number_of_licenses: 10,
      issued_at: 2.years.ago,
      expires_at: 1.year.ago
    )
    assert_equal 0, subscription.available_licenses
  end

  test "used_licenses returns correct count" do
    subscription = Subscription.create!(
      account: @account,
      product: @product,
      number_of_licenses: 10,
      issued_at: Time.current,
      expires_at: 1.year.from_now
    )

    user1 = @account.users.create!(name: "User 1", email: "user1@test.com")
    user2 = @account.users.create!(name: "User 2", email: "user2@test.com")
    user3 = @account.users.create!(name: "User 3", email: "user3@test.com")

    LicenseAssignment.create!(account: @account, user: user1, product: @product)
    LicenseAssignment.create!(account: @account, user: user2, product: @product)
    LicenseAssignment.create!(account: @account, user: user3, product: @product)

    assert_equal 3, subscription.used_licenses
  end
end
