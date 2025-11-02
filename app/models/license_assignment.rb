class LicenseAssignment < ApplicationRecord
  belongs_to :account
  belongs_to :user
  belongs_to :product

  validates :user_id, uniqueness: { scope: [ :account_id, :product_id ],
                                     message: "already has a license for this product" }
  validate :user_belongs_to_account
  validate :subscription_exists_and_has_available_licenses

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
            errors << "#{user&.name} - #{product&.name}: #{assignment.errors.full_messages.join(', ')}"
          end
        end
      end
    end

    { success_count: success_count, errors: errors }
  end

  private

  def user_belongs_to_account
    return if user.blank? || account.blank?

    unless user.account_id == account_id
      errors.add(:user, "must belong to the same account")
    end
  end

  def subscription_exists_and_has_available_licenses
    return if account.blank? || product.blank?

    # Use pessimistic locking to prevent race conditions when checking license availability
    subscription = Subscription.lock.find_by(account: account, product: product)

    if subscription.blank?
      errors.add(:base, "No subscription exists for this product")
      return
    end

    if subscription.expired?
      errors.add(:base, "Subscription has expired")
      return
    end

    # When updating, don't count this assignment against the limit
    existing_assignments = if persisted?
      LicenseAssignment.where(account: account, product: product).where.not(id: id).lock.count
    else
      LicenseAssignment.where(account: account, product: product).lock.count
    end

    if existing_assignments >= subscription.number_of_licenses
      errors.add(:base, "No available licenses for this product")
    end
  end
end
