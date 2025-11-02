require "test_helper"

class LicenseAssignmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:one)
    @product = products(:one)
    @user = users(:one)
  end

  test "should get show" do
    get account_license_assignment_url(@account)
    assert_response :success
  end

  test "should bulk assign licenses" do
    # Create another user without licenses
    user2 = @account.users.create!(name: "Test User", email: "testuser@bulk.com")

    assert_difference("LicenseAssignment.count") do
      post bulk_assign_account_license_assignment_url(@account), params: {
        user_ids: [ user2.id ],
        product_ids: [ @product.id ]
      }
    end

    assert_redirected_to account_license_assignment_url(@account)
    assert_match(/Successfully assigned/, flash[:notice])
  end

  test "should bulk unassign licenses" do
    # Fixture already has an assignment for user one and product one
    # Verify it exists
    assert LicenseAssignment.exists?(account: @account, user: @user, product: @product)

    assert_difference("LicenseAssignment.count", -1) do
      delete bulk_unassign_account_license_assignment_url(@account), params: {
        user_ids: [ @user.id ],
        product_ids: [ @product.id ]
      }
    end

    assert_redirected_to account_license_assignment_url(@account)
    assert_match(/Successfully unassigned/, flash[:notice])
  end

  test "bulk assign with validation errors returns alert" do
    # Fixture already has an assignment for user one and product one
    # Try to assign duplicate (should fail)
    post bulk_assign_account_license_assignment_url(@account), params: {
      user_ids: [ @user.id ],
      product_ids: [ @product.id ]
    }

    assert_redirected_to account_license_assignment_url(@account)
    assert flash[:alert].present?
  end
end
