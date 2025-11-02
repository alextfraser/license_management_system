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
    assert_includes assignment.errors[:base], "No active subscription exists for this product"
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
    assert_includes assignment.errors[:base], "No active subscription exists for this product"
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

  test "renewal scenario: new subscription assignments don't affect old subscription counts" do
    # Clean up the setup subscription that would overlap
    @subscription.destroy!

    # Create users that will be assigned in both old and new subscriptions
    user1 = @account.users.create!(name: "User 1", email: "user1@renewal.com")
    user2 = @account.users.create!(name: "User 2", email: "user2@renewal.com")

    # Create OLD expired subscription with 2 licenses
    old_subscription = Subscription.create!(
      account: @account,
      product: @product,
      number_of_licenses: 2,
      issued_at: Date.new(2023, 1, 1),
      expires_at: Date.new(2023, 12, 31)
    )

    # Assign licenses to user1 and user2 in OLD subscription (backdate them)
    old_assignment1 = LicenseAssignment.new(account: @account, user: user1, product: @product)
    old_assignment1.save(validate: false)
    old_assignment1.update_column(:created_at, Date.new(2023, 6, 1))

    old_assignment2 = LicenseAssignment.new(account: @account, user: user2, product: @product)
    old_assignment2.save(validate: false)
    old_assignment2.update_column(:created_at, Date.new(2023, 6, 1))

    # Old subscription should count its 2 assignments
    assert_equal 2, old_subscription.reload.used_licenses
    assert_equal 0, old_subscription.available_licenses

    # Create NEW active subscription (renewal) with 3 licenses
    new_subscription = Subscription.create!(
      account: @account,
      product: @product,
      number_of_licenses: 3,
      issued_at: 1.month.ago,
      expires_at: 11.months.from_now
    )

    # New subscription starts at 0 used (old assignments don't count)
    assert_equal 0, new_subscription.reload.used_licenses
    assert_equal 3, new_subscription.available_licenses

    # Now we can REASSIGN the SAME users to the new subscription!
    # This is allowed because old subscription is expired (inactive)
    new_assignment1 = LicenseAssignment.create!(account: @account, user: user1, product: @product)
    new_assignment2 = LicenseAssignment.create!(account: @account, user: user2, product: @product)

    # New subscription now has 2 used, 1 available
    assert_equal 2, new_subscription.reload.used_licenses
    assert_equal 1, new_subscription.available_licenses

    # Old subscription STILL counts its 2 (unchanged)
    assert_equal 2, old_subscription.reload.used_licenses

    # Total assignments in DB: 2 old + 2 new = 4
    assert_equal 4, LicenseAssignment.where(account: @account, product: @product).count

    # Now REMOVE one license from new subscription
    new_assignment1.destroy!

    # New subscription drops to 1 used, 2 available
    assert_equal 1, new_subscription.reload.used_licenses
    assert_equal 2, new_subscription.available_licenses

    # Old subscription STILL unchanged (still counts 2)
    assert_equal 2, old_subscription.reload.used_licenses

    # Total in DB: 2 old + 1 new = 3
    assert_equal 3, LicenseAssignment.where(account: @account, product: @product).count
  end

  test "bulk_assign with renewal: respects new subscription limit independently of old" do
    # Clean up the setup subscription that would overlap
    @subscription.destroy!

    # Create OLD expired subscription with 3 assignments
    old_subscription = Subscription.create!(
      account: @account,
      product: @product,
      number_of_licenses: 3,
      issued_at: Date.new(2023, 1, 1),
      expires_at: Date.new(2023, 12, 31)
    )

    # Create 3 users with old assignments (backdated)
    old_user1 = @account.users.create!(name: "Old User 1", email: "olduser1@bulk.com")
    old_user2 = @account.users.create!(name: "Old User 2", email: "olduser2@bulk.com")
    old_user3 = @account.users.create!(name: "Old User 3", email: "olduser3@bulk.com")

    [ old_user1, old_user2, old_user3 ].each do |user|
      assignment = LicenseAssignment.new(account: @account, user: user, product: @product)
      assignment.save(validate: false)
      assignment.update_column(:created_at, Date.new(2023, 6, 1))
    end

    # Old subscription should be full (3/3)
    assert_equal 3, old_subscription.reload.used_licenses

    # Create NEW subscription with only 2 licenses
    new_subscription = Subscription.create!(
      account: @account,
      product: @product,
      number_of_licenses: 2,
      issued_at: 1.month.ago,
      expires_at: 11.months.from_now
    )

    # Create 3 NEW users (different from old users)
    user1 = @account.users.create!(name: "User 1", email: "user1@bulk.com")
    user2 = @account.users.create!(name: "User 2", email: "user2@bulk.com")
    user3 = @account.users.create!(name: "User 3", email: "user3@bulk.com")

    # Bulk assign to all 3 users - should succeed for 2, fail for 1 (new sub only has 2 licenses)
    result = LicenseAssignment.bulk_assign(
      account: @account,
      user_ids: [ user1.id, user2.id, user3.id ],
      product_ids: [ @product.id ]
    )

    assert_equal 2, result[:success_count], "Should successfully assign 2 licenses (new sub limit)"
    assert_equal 1, result[:failed_count], "Should fail 1 assignment (new sub is full)"
    assert_equal 1, result[:errors].length
    assert_match(/No licenses available/, result[:errors].first)

    # Total in DB: 3 old + 2 new = 5
    assert_equal 5, LicenseAssignment.where(account: @account, product: @product).count

    # New subscription only counts its 2
    assert_equal 2, new_subscription.reload.used_licenses

    # Old subscription still counts its 3
    assert_equal 3, old_subscription.reload.used_licenses
  end

  test "cannot assign licenses to expired subscription" do
    # Clean up setup
    @subscription.destroy!

    # Create expired subscription
    expired_sub = Subscription.create!(
      account: @account,
      product: @product,
      number_of_licenses: 10,
      issued_at: Date.new(2023, 1, 1),
      expires_at: Date.new(2023, 12, 31)
    )

    user = @account.users.create!(name: "Test User", email: "test@expired.com")
    assignment = LicenseAssignment.new(account: @account, user: user, product: @product)

    assert_not assignment.valid?
    assert_includes assignment.errors[:base], "No active subscription exists for this product"
  end

  test "can assign up to subscription limit on active subscription" do
    # Use setup subscription (10 licenses, active)
    users = 10.times.map do |i|
      @account.users.create!(name: "User #{i}", email: "user#{i}@limit.com")
    end

    # Assign 10 licenses (should all succeed)
    users.each do |user|
      assignment = LicenseAssignment.create!(account: @account, user: user, product: @product)
      assert assignment.persisted?
    end

    assert_equal 10, @subscription.reload.used_licenses
    assert_equal 0, @subscription.available_licenses

    # 11th assignment should fail
    extra_user = @account.users.create!(name: "Extra User", email: "extra@limit.com")
    assignment = LicenseAssignment.new(account: @account, user: extra_user, product: @product)

    assert_not assignment.valid?
    assert_includes assignment.errors[:base], "No available licenses for this product"
  end

  test "cannot have duplicate active assignment for same user and product" do
    user = @account.users.create!(name: "Duplicate Test", email: "dup@test.com")

    # First assignment succeeds
    assignment1 = LicenseAssignment.create!(account: @account, user: user, product: @product)
    assert assignment1.persisted?

    # Second assignment for same user+product fails (within same active subscription)
    assignment2 = LicenseAssignment.new(account: @account, user: user, product: @product)

    assert_not assignment2.valid?
    assert_includes assignment2.errors[:user_id], "already has a license for this product"
  end

  test "can reassign same user to new subscription after old one expires" do
    @subscription.destroy!

    user = @account.users.create!(name: "Reassign User", email: "reassign@test.com")

    # Old expired subscription with assignment
    old_sub = Subscription.create!(
      account: @account,
      product: @product,
      number_of_licenses: 5,
      issued_at: Date.new(2023, 1, 1),
      expires_at: Date.new(2023, 12, 31)
    )

    old_assignment = LicenseAssignment.new(account: @account, user: user, product: @product)
    old_assignment.save(validate: false)
    old_assignment.update_column(:created_at, Date.new(2023, 6, 1))

    # New active subscription
    new_sub = Subscription.create!(
      account: @account,
      product: @product,
      number_of_licenses: 3,
      issued_at: 1.month.ago,
      expires_at: 11.months.from_now
    )

    # Should be able to assign SAME user to new subscription
    new_assignment = LicenseAssignment.new(account: @account, user: user, product: @product)
    assert new_assignment.valid?, "Should allow reassigning user to new subscription"
    new_assignment.save!

    # Both assignments exist in DB
    assert_equal 2, LicenseAssignment.where(account: @account, user: user, product: @product).count

    # But only new subscription counts the new one
    assert_equal 1, new_sub.reload.used_licenses
    assert_equal 1, old_sub.reload.used_licenses
  end
end
