require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @account = Account.create!(name: "Test Account")
  end

  test "valid user with all attributes" do
    user = @account.users.build(name: "John Doe", email: "john@test.com")
    assert user.valid?
  end

  test "invalid without name" do
    user = @account.users.build(name: nil, email: "john@test.com")
    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
  end

  test "invalid with blank name" do
    user = @account.users.build(name: "", email: "john@test.com")
    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
  end

  test "invalid without email" do
    user = @account.users.build(name: "John Doe", email: nil)
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "invalid with blank email" do
    user = @account.users.build(name: "John Doe", email: "")
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "invalid with duplicate email" do
    @account.users.create!(name: "John Doe", email: "duplicate@test.com")
    user = @account.users.build(name: "Jane Doe", email: "duplicate@test.com")

    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  test "email must be unique across all accounts" do
    account2 = Account.create!(name: "Another Account")
    @account.users.create!(name: "John Doe", email: "shared@test.com")
    user = account2.users.build(name: "Jane Doe", email: "shared@test.com")

    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  test "invalid with malformed email" do
    user = @account.users.build(name: "John Doe", email: "notanemail")
    assert_not user.valid?
    assert_includes user.errors[:email], "is invalid"
  end

  test "valid with proper email format" do
    valid_emails = %w[
      user@example.com
      USER@example.COM
      user.name@example.co.uk
      user+tag@example.com
    ]

    valid_emails.each_with_index do |email, index|
      user = @account.users.build(name: "User #{index}", email: email)
      assert user.valid?, "#{email} should be valid"
    end
  end

  test "belongs to account" do
    user = @account.users.create!(name: "John Doe", email: "john@test.com")
    assert_equal @account, user.account
  end

  test "has many license assignments" do
    user = @account.users.create!(name: "John Doe", email: "john@test.com")
    product = Product.create!(name: "Product A")
    @account.subscriptions.create!(
      product: product,
      number_of_licenses: 10,
      issued_at: Time.current,
      expires_at: 1.year.from_now
    )
    assignment = user.license_assignments.create!(account: @account, product: product)

    assert_equal 1, user.license_assignments.count
    assert_includes user.license_assignments, assignment
  end

  test "has many products through license assignments" do
    user = @account.users.create!(name: "John Doe", email: "john@test.com")
    product1 = Product.create!(name: "Product A")
    product2 = Product.create!(name: "Product B")

    @account.subscriptions.create!(
      product: product1,
      number_of_licenses: 10,
      issued_at: Time.current,
      expires_at: 1.year.from_now
    )
    @account.subscriptions.create!(
      product: product2,
      number_of_licenses: 5,
      issued_at: Time.current,
      expires_at: 1.year.from_now
    )

    user.license_assignments.create!(account: @account, product: product1)
    user.license_assignments.create!(account: @account, product: product2)

    assert_equal 2, user.products.count
    assert_includes user.products, product1
    assert_includes user.products, product2
  end
end
