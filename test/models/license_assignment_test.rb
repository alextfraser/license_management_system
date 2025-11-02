require "test_helper"

class LicenseAssignmentTest < ActiveSupport::TestCase
  setup do
    @account = Account.create!(name: "Test Account")
    @product = Product.create!(name: "Test Product")
    @user = @account.users.create!(name: "Test User", email: "test@test.com")
    @subscription = Subscription.create!(
      account: @account,
      product: @product,
      number_of_licenses: 10,
      issued_at: Time.current,
      expires_at: 1.year.from_now
    )
  end

  test "valid license assignment with all attributes" do
    assignment = LicenseAssignment.new(
      account: @account,
      user: @user,
      product: @product
    )
    assert assignment.valid?
  end

  test "belongs to account" do
    assignment = LicenseAssignment.create!(
      account: @account,
      user: @user,
      product: @product
    )
    assert_equal @account, assignment.account
  end

  test "belongs to user" do
    assignment = LicenseAssignment.create!(
      account: @account,
      user: @user,
      product: @product
    )
    assert_equal @user, assignment.user
  end

  test "belongs to product" do
    assignment = LicenseAssignment.create!(
      account: @account,
      user: @user,
      product: @product
    )
    assert_equal @product, assignment.product
  end

  test "invalid when user already has license for same product" do
    LicenseAssignment.create!(
      account: @account,
      user: @user,
      product: @product
    )

    duplicate = LicenseAssignment.new(
      account: @account,
      user: @user,
      product: @product
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "already has a license for this product"
  end

  test "valid when same user has licenses for different products" do
    product2 = Product.create!(name: "Product 2")
    Subscription.create!(
      account: @account,
      product: product2,
      number_of_licenses: 5,
      issued_at: Time.current,
      expires_at: 1.year.from_now
    )

    assignment1 = LicenseAssignment.create!(
      account: @account,
      user: @user,
      product: @product
    )

    assignment2 = LicenseAssignment.new(
      account: @account,
      user: @user,
      product: product2
    )

    assert assignment2.valid?
  end

  test "invalid when user does not belong to account" do
    other_account = Account.create!(name: "Other Account")
    other_user = other_account.users.create!(name: "Other User", email: "other@test.com")

    assignment = LicenseAssignment.new(
      account: @account,
      user: other_user,
      product: @product
    )

    assert_not assignment.valid?
    assert_includes assignment.errors[:user], "must belong to the same account"
  end

  test "invalid when no subscription exists for product" do
    account2 = Account.create!(name: "Account 2")
    user2 = account2.users.create!(name: "User 2", email: "user2@test.com")
    product2 = Product.create!(name: "Product 2")

    assignment = LicenseAssignment.new(
      account: account2,
      user: user2,
      product: product2
    )

    assert_not assignment.valid?
    assert_includes assignment.errors[:base], "No subscription exists for this product"
  end

  test "invalid when subscription is expired" do
    expired_subscription = Subscription.create!(
      account: @account,
      product: Product.create!(name: "Expired Product"),
      number_of_licenses: 10,
      issued_at: 2.years.ago,
      expires_at: 1.year.ago
    )

    user2 = @account.users.create!(name: "User 2", email: "user2@test.com")
    assignment = LicenseAssignment.new(
      account: @account,
      user: user2,
      product: expired_subscription.product
    )

    assert_not assignment.valid?
    assert_includes assignment.errors[:base], "Subscription has expired"
  end

  test "invalid when no available licenses" do
    # Use up all licenses
    10.times do |i|
      user = @account.users.create!(name: "User #{i}", email: "user#{i}@test.com")
      LicenseAssignment.create!(
        account: @account,
        user: user,
        product: @product
      )
    end

    # Try to assign one more
    extra_user = @account.users.create!(name: "Extra User", email: "extra@test.com")
    assignment = LicenseAssignment.new(
      account: @account,
      user: extra_user,
      product: @product
    )

    assert_not assignment.valid?
    assert_includes assignment.errors[:base], "No available licenses for this product"
  end

  test "bulk_assign creates multiple assignments successfully" do
    users = []
    3.times do |i|
      users << @account.users.create!(name: "User #{i}", email: "user#{i}@test.com")
    end

    result = LicenseAssignment.bulk_assign(
      account: @account,
      user_ids: users.map(&:id),
      product_ids: [ @product.id ]
    )

    assert_equal 3, result[:success_count]
    assert_empty result[:errors]
    assert_equal 3, LicenseAssignment.where(account: @account, product: @product).count
  end

  test "bulk_assign handles multiple products and users" do
    product2 = Product.create!(name: "Product 2")
    Subscription.create!(
      account: @account,
      product: product2,
      number_of_licenses: 5,
      issued_at: Time.current,
      expires_at: 1.year.from_now
    )

    users = []
    2.times do |i|
      users << @account.users.create!(name: "User #{i}", email: "user#{i}@test.com")
    end

    result = LicenseAssignment.bulk_assign(
      account: @account,
      user_ids: users.map(&:id),
      product_ids: [ @product.id, product2.id ]
    )

    assert_equal 4, result[:success_count]  # 2 users × 2 products
    assert_empty result[:errors]
  end

  test "bulk_assign returns errors for invalid assignments" do
    # Create user with existing assignment
    user_with_license = @account.users.create!(name: "User 1", email: "user1@test.com")
    LicenseAssignment.create!(
      account: @account,
      user: user_with_license,
      product: @product
    )

    # Try to assign again
    result = LicenseAssignment.bulk_assign(
      account: @account,
      user_ids: [ user_with_license.id ],
      product_ids: [ @product.id ]
    )

    assert_equal 0, result[:success_count]
    assert_not_empty result[:errors]
    assert_match(/already has/, result[:errors].first)
  end

  test "bulk_assign with no available licenses returns errors" do
    # Use up all 10 licenses
    10.times do |i|
      user = @account.users.create!(name: "User #{i}", email: "user#{i}@test.com")
      LicenseAssignment.create!(
        account: @account,
        user: user,
        product: @product
      )
    end

    # Try to assign to another user
    extra_user = @account.users.create!(name: "Extra User", email: "extra@test.com")
    result = LicenseAssignment.bulk_assign(
      account: @account,
      user_ids: [ extra_user.id ],
      product_ids: [ @product.id ]
    )

    assert_equal 0, result[:success_count]
    assert_not_empty result[:errors]
    assert_match(/No licenses available/, result[:errors].first)
  end

  test "bulk_assign partially succeeds when some assignments fail" do
    # Create one user with existing license
    user1 = @account.users.create!(name: "User 1", email: "user1@test.com")
    LicenseAssignment.create!(
      account: @account,
      user: user1,
      product: @product
    )

    # Create another user without license
    user2 = @account.users.create!(name: "User 2", email: "user2@test.com")

    result = LicenseAssignment.bulk_assign(
      account: @account,
      user_ids: [ user1.id, user2.id ],
      product_ids: [ @product.id ]
    )

    assert_equal 1, result[:success_count]
    assert_equal 1, result[:errors].length
  end
end
