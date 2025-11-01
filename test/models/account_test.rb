require "test_helper"

class AccountTest < ActiveSupport::TestCase
  test "valid account with name" do
    account = Account.new(name: "Acme Corp")
    assert account.valid?
  end

  test "invalid without name" do
    account = Account.new(name: nil)
    assert_not account.valid?
    assert_includes account.errors[:name], "can't be blank"
  end

  test "invalid with blank name" do
    account = Account.new(name: "")
    assert_not account.valid?
    assert_includes account.errors[:name], "can't be blank"
  end

  test "has many users" do
    account = Account.create!(name: "Test Corp")
    user1 = account.users.create!(name: "Alice Smith", email: "alice@test.com")
    user2 = account.users.create!(name: "Bob Jones", email: "bob@test.com")

    assert_equal 2, account.users.count
    assert_includes account.users, user1
    assert_includes account.users, user2
  end

  test "has many subscriptions" do
    account = Account.create!(name: "Acme Corp")
    product = Product.create!(name: "Product A")
    subscription = account.subscriptions.create!(
      product: product,
      number_of_licenses: 10,
      issued_at: Time.current,
      expires_at: 1.year.from_now
    )

    assert_equal 1, account.subscriptions.count
    assert_includes account.subscriptions, subscription
  end

  test "has many license assignments" do
    account = Account.create!(name: "Test Corp 2")
    user = account.users.create!(name: "Charlie Brown", email: "charlie@test.com")
    product = Product.create!(name: "Product A")
    account.subscriptions.create!(
      product: product,
      number_of_licenses: 10,
      issued_at: Time.current,
      expires_at: 1.year.from_now
    )
    assignment = account.license_assignments.create!(user: user, product: product)

    assert_equal 1, account.license_assignments.count
    assert_includes account.license_assignments, assignment
  end

  test "has many products through subscriptions" do
    account = Account.create!(name: "Acme Corp")
    product1 = Product.create!(name: "Product A")
    product2 = Product.create!(name: "Product B")

    account.subscriptions.create!(
      product: product1,
      number_of_licenses: 10,
      issued_at: Time.current,
      expires_at: 1.year.from_now
    )
    account.subscriptions.create!(
      product: product2,
      number_of_licenses: 5,
      issued_at: Time.current,
      expires_at: 1.year.from_now
    )

    assert_equal 2, account.products.count
    assert_includes account.products, product1
    assert_includes account.products, product2
  end

  test "destroys dependent users when account is destroyed" do
    account = Account.create!(name: "Test Corp 3")
    user = account.users.create!(name: "David Lee", email: "david@test.com")
    user_id = user.id

    account.destroy

    assert_nil User.find_by(id: user_id)
  end

  test "destroys dependent subscriptions when account is destroyed" do
    account = Account.create!(name: "Acme Corp")
    product = Product.create!(name: "Product A")
    subscription = account.subscriptions.create!(
      product: product,
      number_of_licenses: 10,
      issued_at: Time.current,
      expires_at: 1.year.from_now
    )
    subscription_id = subscription.id

    account.destroy

    assert_nil Subscription.find_by(id: subscription_id)
  end

  test "destroys dependent license assignments when account is destroyed" do
    account = Account.create!(name: "Test Corp 4")
    user = account.users.create!(name: "Eve Wilson", email: "eve@test.com")
    product = Product.create!(name: "Product A")
    account.subscriptions.create!(
      product: product,
      number_of_licenses: 10,
      issued_at: Time.current,
      expires_at: 1.year.from_now
    )
    assignment = account.license_assignments.create!(user: user, product: product)
    assignment_id = assignment.id

    account.destroy

    assert_nil LicenseAssignment.find_by(id: assignment_id)
  end
end
