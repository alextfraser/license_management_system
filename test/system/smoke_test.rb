require "application_system_test_case"

# Single smoke test to verify the application loads correctly.
# smoke tests that catch configuration issues, not business logic testing.
class SmokeTest < ApplicationSystemTestCase
  test "application loads and basic navigation works" do
    # Verify root path loads
    visit root_path
    assert_text "License Management"

    # Verify accounts page loads
    click_on "Accounts"
    assert_selector "h1", text: "Accounts"

    # Verify products page loads
    click_on "Products"
    assert_selector "h1", text: "Products"

    # Verify we can navigate to create a new account
    click_on "Accounts"
    click_on "New Account"
    assert_selector "h1", text: "New Account"
  end
end
