require "application_system_test_case"

# Single smoke test to verify the application loads correctly.
# Smoke tests catch configuration issues, not business logic testing.
class SmokeTest < ApplicationSystemTestCase
  test "application loads and all major pages are accessible" do
    # Create test data for navigation
    account = Account.create!(name: "Smoke Test Account")
    product = Product.create!(name: "Test Product", description: "For testing")
    user = account.users.create!(name: "Test User", email: "smoke@test.com")
    subscription = account.subscriptions.create!(
      product: product,
      number_of_licenses: 5,
      issued_at: Time.current,
      expires_at: 1.year.from_now
    )

    # Verify root path loads with navigation
    visit root_path
    assert_text "License Management"
    assert_link "Accounts"
    assert_link "Products"

    # Verify accounts list page
    click_on "Accounts"
    assert_selector "h1", text: "Accounts"
    assert_text "Smoke Test Account"
    assert_link "New Account"

    # Verify new account page
    click_on "New Account"
    assert_selector "h1", text: "New Account"
    assert_field "Name"
    assert_button "Create Account"  # This is a real button (form submit)

    # Verify account detail page
    visit account_path(account)
    assert_selector "h1", text: "Smoke Test Account"
    assert_link "Manage Users"
    assert_link "Manage Subscriptions"
    assert_link "Assign Licenses"

    # Verify users page for account
    click_on "Manage Users"
    assert_selector "h1", text: "Users"
    assert_text "Test User"
    assert_link "Add User"

    # Verify new user page
    click_on "Add User"
    assert_selector "h1", text: "Add User"
    assert_field "Name"
    assert_field "Email"
    assert_button "Add User"

    # Verify subscriptions page
    visit account_subscriptions_path(account)
    assert_selector "h1", text: "Subscriptions"
    assert_text "Test Product"
    assert_link "Add Subscription"

    # Verify new subscription page
    click_on "Add Subscription"
    assert_selector "h1", text: "Add Subscription"
    assert_field "Number of Licenses"
    assert_button "Add Subscription"

    # Verify license assignment page (the main feature)
    visit account_license_assignment_path(account)
    assert_selector "h1", text: "Account: Smoke Test Account"
    assert_text "Product Licenses"
    assert_text "Users"
    assert_button "Assign", disabled: true
    assert_button "Unassign", disabled: true
    assert_text "Test Product"
    assert_text "Test User"

    # Verify products list page
    visit products_path
    assert_selector "h1", text: "Products"
    assert_text "Test Product"
    assert_link "New Product"

    # Verify new product page
    click_on "New Product"
    assert_selector "h1", text: "New Product"
    assert_field "Name"
    assert_field "Description"
    assert_button "Create Product"

    # Verify product detail page
    visit product_path(product)
    assert_selector "h1", text: "Test Product"
    assert_text "For testing"
  end
end
