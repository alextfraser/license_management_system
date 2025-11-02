class LicenseAssignment < ApplicationRecord
  belongs_to :account
  belongs_to :user
  belongs_to :product

  validate :user_belongs_to_account
  validate :no_duplicate_active_assignment
  validate :subscription_exists_and_has_available_licenses

  # Bulk assignment allows partial success for better UX.
  # Uses pessimistic locking to prevent race conditions.
  def self.bulk_assign(account:, user_ids:, product_ids:)
    errors = []
    success_count = 0

    product_ids.each do |product_id|
      user_ids.each do |user_id|
        ActiveRecord::Base.transaction do
          assignment = new(
            account: account,
            user_id: user_id,
            product_id: product_id
          )

          if assignment.save
            success_count += 1
          else
            user = User.find_by(id: user_id)
            product = Product.find_by(id: product_id)
            error_msg = assignment.errors.full_messages.first || "Unknown error"
            errors << "#{user&.name} already has #{product&.name}" if error_msg.include?("already has")
            errors << "No licenses available for #{product&.name}" if error_msg.include?("No available")
            errors << "No active subscription for #{product&.name}" if error_msg.include?("No active subscription")
            errors << error_msg unless error_msg.include?("already has") || error_msg.include?("No available") || error_msg.include?("No active subscription")
          end
        end
      end
    end

    {
      success_count: success_count,
      failed_count: errors.size,
      errors: errors
    }
  end

  private

  def user_belongs_to_account
    return if user.blank? || account.blank?

    unless user.account_id == account_id
      errors.add(:user, "must belong to the same account")
    end
  end

  def no_duplicate_active_assignment
    return if user.blank? || account.blank? || product.blank?

    active_subscription = Subscription.active.find_by(account: account, product: product)
    return unless active_subscription

    existing_active = LicenseAssignment.where(
      account: account,
      user: user,
      product: product
    ).where("created_at >= ?", active_subscription.issued_at)

    existing_active = existing_active.where.not(id: id) if persisted?

    if existing_active.exists?
      errors.add(:user_id, "already has a license for this product")
    end
  end

  def subscription_exists_and_has_available_licenses
    return if account.blank? || product.blank?

    subscription = Subscription.active.lock.find_by(account: account, product: product)

    if subscription.blank?
      errors.add(:base, "No active subscription exists for this product")
      return
    end

    assignments_scope = LicenseAssignment.where(account: account, product: product)
      .where("created_at >= ?", subscription.issued_at)
      .lock

    existing_assignments = if persisted?
      assignments_scope.where.not(id: id).count
    else
      assignments_scope.count
    end

    if existing_assignments >= subscription.number_of_licenses
      errors.add(:base, "No available licenses for this product")
    end
  end
end
