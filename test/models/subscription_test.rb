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

  test "active scope returns only currently active subscriptions" do
    # Create active subscription (started and not expired)
    active_sub = Subscription.create!(
      account: @account,
      product: @product,
      number_of_licenses: 10,
      issued_at: 1.month.ago,
      expires_at: 11.months.from_now
    )

    # Create expired subscription
    expired_sub = Subscription.create!(
      account: Account.create!(name: "Another Account"),
      product: Product.create!(name: "Another Product"),
      number_of_licenses: 5,
      issued_at: 2.years.ago,
      expires_at: 1.year.ago
    )

    # Create future subscription (not started yet)
    future_sub = Subscription.create!(
      account: Account.create!(name: "Future Account"),
      product: Product.create!(name: "Future Product"),
      number_of_licenses: 3,
      issued_at: 1.month.from_now,
      expires_at: 1.year.from_now
    )

    active_subscriptions = Subscription.active

    assert_includes active_subscriptions, active_sub, "Should include started, non-expired subscription"
    assert_not_includes active_subscriptions, expired_sub, "Should not include expired subscription"
    assert_not_includes active_subscriptions, future_sub, "Should not include future subscription"
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

  test "invalid when creating overlapping subscription for same account and product" do
    # Create first subscription: Jan 1 - Dec 31, 2026
    Subscription.create!(
      account: @account,
      product: @product,
      number_of_licenses: 10,
      issued_at: Time.new(2026, 1, 1),
      expires_at: Time.new(2026, 12, 31)
    )

    # Try to create overlapping subscription: June 1, 2026 - Dec 31, 2027
    overlapping_subscription = Subscription.new(
      account: @account,
      product: @product,
      number_of_licenses: 5,
      issued_at: Time.new(2026, 6, 1),
      expires_at: Time.new(2027, 12, 31)
    )

    assert_not overlapping_subscription.valid?
    assert_includes overlapping_subscription.errors[:base], "Date range overlaps with an existing subscription for this product"
  end

  test "valid when creating subscription for expired product (renewal)" do
    # Create expired subscription
    Subscription.create!(
      account: @account,
      product: @product,
      number_of_licenses: 10,
      issued_at: 2.years.ago,
      expires_at: 1.year.ago
    )

    # Create new subscription for same product (renewal)
    renewal_subscription = Subscription.new(
      account: @account,
      product: @product,
      number_of_licenses: 15,
      issued_at: Time.current,
      expires_at: 1.year.from_now
    )

    assert renewal_subscription.valid?
  end

  test "valid when creating future non-overlapping subscription" do
    # Create current subscription: Jan 1 - Dec 31, 2026
    Subscription.create!(
      account: @account,
      product: @product,
      number_of_licenses: 10,
      issued_at: Time.new(2026, 1, 1),
      expires_at: Time.new(2026, 12, 31)
    )

    # Create future subscription starting when current expires: Jan 1 - Dec 31, 2027
    future_subscription = Subscription.new(
      account: @account,
      product: @product,
      number_of_licenses: 15,
      issued_at: Time.new(2027, 1, 1),
      expires_at: Time.new(2027, 12, 31)
    )

    assert future_subscription.valid?, "Should allow future subscription that doesn't overlap"
  end

  test "valid when different accounts subscribe to same product" do
    account2 = Account.create!(name: "Another Account")

    # First account subscribes
    Subscription.create!(
      account: @account,
      product: @product,
      number_of_licenses: 10,
      issued_at: Time.current,
      expires_at: 1.year.from_now
    )

    # Second account subscribes to same product
    subscription2 = Subscription.new(
      account: account2,
      product: @product,
      number_of_licenses: 5,
      issued_at: Time.current,
      expires_at: 1.year.from_now
    )

    assert subscription2.valid?
  end

  test "valid when same account subscribes to different products" do
    product2 = Product.create!(name: "Another Product")

    # Subscribe to first product
    Subscription.create!(
      account: @account,
      product: @product,
      number_of_licenses: 10,
      issued_at: Time.current,
      expires_at: 1.year.from_now
    )

    # Subscribe to different product
    subscription2 = Subscription.new(
      account: @account,
      product: product2,
      number_of_licenses: 5,
      issued_at: Time.current,
      expires_at: 1.year.from_now
    )

    assert subscription2.valid?
  end

  test "used_licenses only counts assignments from this subscription period" do
    # Create old expired subscription
    old_sub = Subscription.create!(
      account: @account,
      product: @product,
      number_of_licenses: 5,
      issued_at: 2.years.ago,
      expires_at: 1.year.ago
    )

    # Create old assignments (backdated)
    user1 = @account.users.create!(name: "User 1", email: "user1@period.com")
    user2 = @account.users.create!(name: "User 2", email: "user2@period.com")

    assignment1 = LicenseAssignment.new(account: @account, user: user1, product: @product)
    assignment1.save(validate: false) # Bypass validation
    assignment1.update_column(:created_at, 18.months.ago) # Backdate to old subscription period

    assignment2 = LicenseAssignment.new(account: @account, user: user2, product: @product)
    assignment2.save(validate: false)
    assignment2.update_column(:created_at, 18.months.ago)

    # Old subscription should count old assignments
    assert_equal 2, old_sub.used_licenses, "Old subscription should count its 2 assignments"

    # Create new subscription
    new_sub = Subscription.create!(
      account: @account,
      product: @product,
      number_of_licenses: 3,
      issued_at: Time.current,
      expires_at: 1.year.from_now
    )

    # New subscription should NOT count old assignments
    assert_equal 0, new_sub.used_licenses, "New subscription should not count old assignments"

    # Total assignments in DB unchanged
    assert_equal 2, LicenseAssignment.where(account: @account, product: @product).count
  end
end
