class LicenseAssignmentsController < ApplicationController
  before_action :set_account

  def show
    @users = @account.users
    @subscriptions = @account.subscriptions.includes(:product).active
    @license_assignments = @account.license_assignments.includes(:user, :product)

    @assignments_by_user_and_product = @license_assignments.each_with_object({}) do |assignment, hash|
      hash[[ assignment.user_id, assignment.product_id ]] = assignment
    end
  end

  def bulk_assign
    result = LicenseAssignment.bulk_assign(
      account: @account,
      user_ids: params[:user_ids] || [],
      product_ids: params[:product_ids] || []
    )

    if result[:errors].empty?
      redirect_to account_license_assignment_path(@account),
                  notice: "#{result[:success_count]} assigned successfully"
    else
      displayed_errors = result[:errors].first(5)
      remaining = result[:failed_count] - displayed_errors.size

      message = "#{result[:success_count]} assigned, #{result[:failed_count]} failed. First #{displayed_errors.size} errors:\n" +
                displayed_errors.map { |error| "• #{error}" }.join("\n")

      message += "\n... and #{remaining} more errors" if remaining > 0

      redirect_to account_license_assignment_path(@account), alert: message
    end
  end

  def bulk_unassign
    product_ids = params[:product_ids] || []
    user_ids = params[:user_ids] || []

    assignments = @account.license_assignments
      .where(user_id: user_ids, product_id: product_ids)

    count = assignments.count
    assignments.destroy_all

    redirect_to account_license_assignment_path(@account),
                notice: "#{count} unassigned successfully"
  end

  private

  def set_account
    @account = Account.find(params[:account_id])
  end
end
