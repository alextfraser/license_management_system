require "test_helper"

class ProductTest < ActiveSupport::TestCase
  test "valid product with name" do
    product = Product.new(name: "Microsoft Office")
    assert product.valid?
  end

  test "valid product with name and description" do
    product = Product.new(name: "Microsoft Office", description: "Productivity suite")
    assert product.valid?
  end

  test "invalid without name" do
    product = Product.new(name: nil)
    assert_not product.valid?
    assert_includes product.errors[:name], "can't be blank"
  end

  test "invalid with blank name" do
    product = Product.new(name: "")
    assert_not product.valid?
    assert_includes product.errors[:name], "can't be blank"
  end

  test "valid without description" do
    product = Product.new(name: "Microsoft Office")
    assert product.valid?
  end

  test "has many subscriptions" do
    product = Product.create!(name: "Product A")
    account1 = Account.create!(name: "Account 1")
    account2 = Account.create!(name: "Account 2")

    sub1 = product.subscriptions.create!(
      account: account1,
      number_of_licenses: 10,
      issued_at: Time.current,
      expires_at: 1.year.from_now
    )
    sub2 = product.subscriptions.create!(
      account: account2,
      number_of_licenses: 5,
      issued_at: Time.current,
      expires_at: 1.year.from_now
    )

    assert_equal 2, product.subscriptions.count
    assert_includes product.subscriptions, sub1
    assert_includes product.subscriptions, sub2
  end

  test "has many accounts through subscriptions" do
    product = Product.create!(name: "Product A")
    account1 = Account.create!(name: "Account 1")
    account2 = Account.create!(name: "Account 2")

    product.subscriptions.create!(
      account: account1,
      number_of_licenses: 10,
      issued_at: Time.current,
      expires_at: 1.year.from_now
    )
    product.subscriptions.create!(
      account: account2,
      number_of_licenses: 5,
      issued_at: Time.current,
      expires_at: 1.year.from_now
    )

    assert_equal 2, product.accounts.count
    assert_includes product.accounts, account1
    assert_includes product.accounts, account2
  end

  test "destroys dependent subscriptions when product is destroyed" do
    product = Product.create!(name: "Product A")
    account = Account.create!(name: "Account 1")
    subscription = product.subscriptions.create!(
      account: account,
      number_of_licenses: 10,
      issued_at: Time.current,
      expires_at: 1.year.from_now
    )
    subscription_id = subscription.id

    product.destroy

    assert_nil Subscription.find_by(id: subscription_id)
  end
end
